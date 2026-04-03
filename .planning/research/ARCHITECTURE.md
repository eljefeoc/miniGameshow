# Architecture Research

**Project:** MiniGameshow
**Researched:** 2026-04-02
**Confidence:** HIGH (analysis based on actual codebase + well-established Supabase patterns)

---

## Event System Design

### The Problem with the Current "Week" Model

The `weeks` table is semantically correct but structurally inflexible:

1. **Name is too narrow.** "Week" implies a fixed 7-day window. The requirement is configurable duration (hours to days to a week). The table supports it via `starts_at`/`ends_at` but the name creates conceptual drag — future developers will be confused when a "week" lasts 4 hours.
2. **No lifecycle state column.** Active/inactive is currently inferred by checking `now()` between `starts_at` and `ends_at`. This makes it impossible to: (a) have a published-but-not-yet-live event, (b) have an admin manually end an event early, (c) distinguish "internal test" from "public competition."
3. **No event classification.** All weeks are implicitly prize competitions. Test events, practice events, and future corporate events have no representation.

### Recommended Migration: Rename + Augment `weeks` → `events`

Rename the table to `events` (migration with `ALTER TABLE public.weeks RENAME TO public.events`, update all FK references). This is a one-time rename that clarifies intent without changing the underlying structure.

Add these columns:

```sql
ALTER TABLE public.events
  RENAME TO public.events;  -- conceptual rename in migrations

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS status text NOT NULL DEFAULT 'draft'
    CHECK (status IN ('draft', 'scheduled', 'live', 'ended', 'archived')),
  ADD COLUMN IF NOT EXISTS event_type text NOT NULL DEFAULT 'competition'
    CHECK (event_type IN ('competition', 'test', 'practice')),
  ADD COLUMN IF NOT EXISTS published_at timestamptz,
  ADD COLUMN IF NOT EXISTS ended_at timestamptz;
```

**Status lifecycle:**

```
draft → scheduled → live → ended → archived
           ↑                ↑
     (admin publish)   (admin end OR ends_at passes)
```

- `draft`: being configured, not visible to players
- `scheduled`: published, visible in HUD countdown, scoring not yet open
- `live`: scoring window is open; runs accepted
- `ended`: scoring closed, winner determinable; runs rejected
- `archived`: post-show, historical record only

**Why this over time-only gating:** Time-gating alone (`starts_at`/`ends_at`) means admins cannot soft-close an event or delay opening without editing timestamps. The `status` column gives the admin panel a one-click "Go live" / "End event" control. The DB trigger still enforces both status AND time to accept runs.

**event_type field:**

- `competition`: public, prize eligible, appears in public leaderboard
- `test`: admin-only, excluded from public flows, winner suppressed
- `practice`: public, no prize, under-18 players can participate, separate leaderboard view

### DB Changes Summary

| Change | Migration | Impact |
|--------|-----------|--------|
| Add `status` column to `weeks` | New migration | Triggers updated to check status |
| Add `event_type` column | New migration | RLS and leaderboard queries filter on it |
| Add `published_at`, `ended_at` | New migration | Admin audit trail |
| Add `age_verification` table | New migration | Separate from profiles (see below) |
| Rename `weeks` → `events` (future) | Post-v1 | Coordinate with all FK references |

For v1, do **not** rename `weeks` to avoid a large churn migration mid-build. Add the columns, update the code to treat `weeks` as events conceptually, and do the rename as a dedicated cleanup migration when bandwidth allows.

**Updated `before_run_insert` trigger must check:**

```sql
-- In before_run_insert, after the attempt limit check:
IF NOT EXISTS (
  SELECT 1 FROM public.weeks w
  WHERE w.id = NEW.week_id
    AND w.status = 'live'
    AND now() BETWEEN w.starts_at AND w.ends_at
) THEN
  RAISE EXCEPTION 'event_not_accepting_runs';
END IF;
```

This enforces cutoff server-side in the DB trigger — no Edge Function required for the basic case (see Server-side Cutoff Enforcement below).

---

## Multi-Game Plugin Pattern

### The Problem

`penguin-game.html` hardcodes `slug = 'pengu-fisher'` in `fetchActiveWeek()` and `submitRunToSupabase()`. Every game currently needs to re-implement the same Supabase auth, event lookup, run submission, and HUD wiring. `fish-stack.html` has none of this yet.

### Recommended Pattern: `gameshow-client.js` Module

Extract the shared Supabase/event/submission logic into a single IIFE module following the same pattern as `hud.js`. Every game file includes it alongside `hud.js` and calls a simple API.

**Contract:**

```javascript
// Each game calls:
GameshowClient.init({ gameSlug: 'pengu-fisher' });

// Then uses:
await GameshowClient.getActiveEvent();   // → { id, prize_title, ends_at, ... } or null
await GameshowClient.submitRun({ score, durationMs, daySeed, gameVersion, replayPayload });
// returns { ok: true, rank, best } or { ok: false, error }

GameshowClient.getSession();             // → supabase session or null
GameshowClient.getSupabase();            // → supabase client instance
GameshowClient.onAuthChange(callback);  // fires on sign-in / sign-out
```

**What the module owns:**
- Supabase client initialization (reads `window.__MINIGAMESHOW_SUPABASE__`)
- Auth session management and `onAuthStateChange` listener
- `fetchActiveEvent(gameSlug)` — replaces per-game `fetchActiveWeek()`
- `submitRun(payload)` — validates event status client-side, inserts to `runs`, returns updated rank
- Age/competition eligibility check (reads `age_verification` table)
- Attempt count tracking

**What each game owns:**
- Canvas/rendering logic
- Game-specific HUD wiring (`GameshowHud.setStats(...)`, etc.)
- Game-specific overlay states
- Its own `gameSlug` constant

**Loading order in every game HTML:**

```html
<script src="supabase-config.js"></script>
<script src="hud.js"></script>
<script src="gameshow-client.js"></script>
<!-- game-specific JS inline or as separate file -->
```

**Why IIFE over ES module:** The no-build-step constraint means no import maps or bundler. IIFE modules loaded as `<script>` tags load synchronously in order and expose globals without any tooling. This is the same pattern already proven by `hud.js`.

### DB: No Changes Needed

The `games` table already exists. Each game just needs a row inserted:

```sql
INSERT INTO public.games (slug, name) VALUES ('fish-stack', 'Fish Stack') ON CONFLICT DO NOTHING;
```

The `events`/`weeks` table already has `game_id`. The plugin pattern is entirely at the JS layer.

---

## Admin → Publish Flow

### Current State

Admin can INSERT and UPDATE rows in `weeks` via RLS policies gated on `profiles.is_admin = true`. This is correct and should be preserved.

### The Publish Flow with Status

The admin panel needs to drive the event lifecycle. The flow is:

```
1. Admin creates event (status='draft')
2. Admin fills in prize, game, dates, show_at
3. Admin clicks "Publish" → status='scheduled'
   (event appears in HUD countdown; no scoring yet)
4. Either: starts_at passes → DB auto-transitions to 'live' via trigger
   Or: Admin clicks "Go Live" manually → status='live'
5. ends_at passes → DB trigger transitions to 'ended'
   Or: Admin clicks "End Event" → status='ended'
6. Admin reviews winner in admin panel (rank=1 leaderboard row)
7. Admin archives → status='archived'
```

### Implementation: Trigger-Driven Auto-Transition

Add a Postgres function called by a **pg_cron job** (available in Supabase Pro) or triggered on-read. Since the project is on free/starter tier without pg_cron, use a simpler approach:

**Auto-transition on run insert:** The `before_run_insert` trigger already queries the event. Extend it to auto-set `status='live'` if `starts_at <= now()` and current status is `scheduled`. Similarly set `status='ended'` if `ends_at < now()` and status is `live`.

**Auto-transition on leaderboard read:** The `fetchActiveEvent` function in `gameshow-client.js` can also check timestamp bounds and surface "no active event" even if status says `live` — a client-side safety check layered over the DB enforcement.

**Admin RPC for manual transitions:**

```sql
CREATE OR REPLACE FUNCTION public.admin_set_event_status(
  p_event_id uuid,
  p_status text
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true
  ) THEN
    RAISE EXCEPTION 'Admin only';
  END IF;

  UPDATE public.weeks
  SET status = p_status,
      published_at = CASE WHEN p_status = 'scheduled' AND published_at IS NULL
                          THEN now() ELSE published_at END,
      ended_at = CASE WHEN p_status = 'ended' AND ended_at IS NULL
                      THEN now() ELSE ended_at END
  WHERE id = p_event_id;
END;
$$;
```

The admin panel calls `sb.rpc('admin_set_event_status', { p_event_id, p_status })`.

### RLS for Event Management

Keep the existing `weeks_insert_admin` and `weeks_update_admin` policies. Add a DELETE policy:

```sql
CREATE POLICY "weeks_delete_admin"
  ON public.weeks FOR DELETE
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );
```

Only admins can delete events. Players cannot read draft events:

```sql
-- Replace the current open weeks_select_all policy with a scoped one:
DROP POLICY IF EXISTS "weeks_select_all" ON public.weeks;

CREATE POLICY "weeks_select_published"
  ON public.weeks FOR SELECT
  USING (
    status IN ('scheduled', 'live', 'ended', 'archived')
    OR EXISTS (
      SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true
    )
  );
```

This hides `draft` events from players while admins see everything.

---

## Age Verification Storage

### The Privacy Problem

Age verification data (DOB, verification method, outcome) is sensitive. Storing it directly in `profiles` means:
- Any `profiles_select_public` RLS leak exposes it
- It contaminates a table that's frequently SELECTed for leaderboard display names
- Future compliance requirements (GDPR, COPPA) are harder when PII is mixed with gameplay data

### Recommended: Separate `age_verifications` Table

```sql
CREATE TABLE public.age_verifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  verified_at timestamptz NOT NULL DEFAULT now(),
  method text NOT NULL DEFAULT 'self_declaration'
    CHECK (method IN ('self_declaration', 'id_check', 'credit_card')),
  birth_year smallint,          -- year only, not full DOB
  is_18_plus boolean NOT NULL,
  jurisdiction text,            -- ISO country code for geo framework
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id)              -- one active verification per user
);

ALTER TABLE public.age_verifications ENABLE ROW LEVEL SECURITY;

-- Users can only read and create their own verification:
CREATE POLICY "age_verifications_select_own"
  ON public.age_verifications FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "age_verifications_insert_own"
  ON public.age_verifications FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

-- Admins can read for compliance:
CREATE POLICY "age_verifications_select_admin"
  ON public.age_verifications FOR SELECT
  TO authenticated
  USING (
    EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true)
  );
```

**Store `birth_year` not full DOB.** For v1 self-declaration, you only need to know "18+" or not. Full DOB creates unnecessary PII. If ID verification is added later, that detail lives in a separate provider's system.

**Add a denormalized `competition_eligible` column to `profiles`:**

```sql
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS competition_eligible boolean NOT NULL DEFAULT false;
```

This column is set by a trigger on `age_verifications` insert/update. It lets the leaderboard queries and run-submission checks avoid joining to `age_verifications` on every request:

```sql
CREATE OR REPLACE FUNCTION public.after_age_verification_upsert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.profiles
  SET competition_eligible = NEW.is_18_plus
  WHERE id = NEW.user_id;
  RETURN NEW;
END;
$$;

CREATE TRIGGER age_verifications_after_upsert
  AFTER INSERT OR UPDATE ON public.age_verifications
  FOR EACH ROW
  EXECUTE FUNCTION public.after_age_verification_upsert();
```

**Under-18 practice mode:** When `competition_eligible = false`, the `before_run_insert` trigger should route the run to an under-18 leaderboard. The simplest v1 approach is a boolean column on `runs`:

```sql
ALTER TABLE public.runs
  ADD COLUMN IF NOT EXISTS is_practice boolean NOT NULL DEFAULT false;
```

The trigger sets `is_practice = NOT profiles.competition_eligible` on insert. Leaderboard queries filter by `is_practice = false` for the prize leaderboard, `is_practice = true` for the practice board. No separate table needed.

**Why not check `age_verifications` directly in RLS on runs:** RLS policies execute per-row and the join would fire on every run insert. The denormalized `competition_eligible` on `profiles` is a single column read in a trigger — much cheaper.

---

## Routing Structure

### Current State

`vercel.json` has a single rewrite: `/ → /penguin-game.html`. The `outputDirectory` is `prototypes/`. Everything is flat files in that directory.

### Recommended Vercel Routing

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "buildCommand": "npm run build",
  "outputDirectory": "prototypes",
  "rewrites": [
    { "source": "/",              "destination": "/shell.html" },
    { "source": "/play",          "destination": "/shell.html" },
    { "source": "/play/:game",    "destination": "/shell.html" },
    { "source": "/profile",       "destination": "/profile.html" },
    { "source": "/leaderboard",   "destination": "/leaderboard.html" },
    { "source": "/admin",         "destination": "/admin.html" }
  ]
}
```

**Why a `shell.html` at `/`:**

The player-facing entry point should be a lightweight shell that:
1. Reads a `?game=pengu-fisher` query param (or defaults to the active event's game)
2. Dynamically loads the correct game's JS/assets
3. Mounts the HUD
4. Handles auth state and the "signed out" welcome experience

This avoids the current `/ → /penguin-game.html` coupling. When Game 02 ships, `/` automatically shows whichever game the current active event is configured for — admin sets `game_id` on the event, shell reads it.

**Game HTML files stay in `prototypes/` as `/game/pengu-fisher.html`, etc.** The shell can iframe them (simpler isolation) or inline-load their canvas (harder but better UX). For v1 with vanilla JS, **iframe is the wrong call** — it creates cross-frame communication complexity and breaks the shared `gameshow-client.js` globals. Instead, the shell uses `fetch()` to load game HTML content into a div, or more practically: each game remains a full HTML file that the shell rewrites to directly.

**Practical v1 routing approach:**

```json
"rewrites": [
  { "source": "/",           "destination": "/penguin-game.html" },
  { "source": "/fish-stack", "destination": "/fish-stack.html" },
  { "source": "/admin",      "destination": "/admin.html" },
  { "source": "/profile",    "destination": "/profile.html" },
  { "source": "/leaderboard","destination": "/leaderboard.html" }
]
```

The game at `/` changes when the admin changes which game is the active event default. For v1 with one active event at a time, this is fine — the "wrong" game just shows "no active event." A future smart shell can read the event and redirect.

**Security headers:** Add to `vercel.json`:

```json
"headers": [
  {
    "source": "/admin",
    "headers": [
      { "key": "X-Frame-Options", "value": "DENY" },
      { "key": "X-Content-Type-Options", "value": "nosniff" }
    ]
  }
]
```

Admin panel should not be iframeable. The existing `is_admin` RLS check is the auth gate, but defense in depth matters.

**`/profile` and `/leaderboard`:** These are new standalone HTML files to create. They share the same `supabase-config.js`, `hud.js`, and `gameshow-client.js` loading pattern as the game files. No routing framework needed.

---

## Server-side Cutoff Enforcement

### The Problem

Currently, the client checks `ends_at` before submitting a run, but this is bypassable. Anyone can intercept the Supabase call and insert a run after cutoff. The DB trigger enforces attempt limits but not time/status gating on runs.

### Recommended: Layered Enforcement Without an App Server

**Layer 1: DB trigger (highest authority)**

Extend `before_run_insert` to reject runs against closed events:

```sql
-- Add to before_run_insert, BEFORE the attempt count logic:
DECLARE
  v_event_status text;
  v_event_ends timestamptz;
BEGIN
  SELECT w.status, w.ends_at
  INTO v_event_status, v_event_ends
  FROM public.weeks w
  WHERE w.id = NEW.week_id;

  IF v_event_status IS NULL THEN
    RAISE EXCEPTION 'event_not_found';
  END IF;

  IF v_event_status NOT IN ('live') THEN
    RAISE EXCEPTION 'event_not_accepting_runs: status=%', v_event_status;
  END IF;

  IF now() > v_event_ends THEN
    RAISE EXCEPTION 'event_cutoff_passed';
  END IF;
  -- ... rest of trigger
```

This is enforced in Postgres, bypasses no RLS policy, and fires even if a client uses the service role key (which should never be client-side anyway). This is the only truly server-side enforcement available without an app server.

**Layer 2: Supabase Edge Function for submit (optional, adds latency)**

An Edge Function `POST /functions/v1/submit-run` that:
1. Validates the JWT (user is authenticated)
2. Checks the event status/timing
3. Inserts the run using the service role (bypasses RLS, trusts the function's own checks)
4. Returns the updated rank

Edge Functions run in Deno at the edge and have access to environment variables including the service role key. This is the right pattern when you need to add business logic (anti-cheat scoring validation, rate limiting) that can't live in a trigger.

**For v1, the DB trigger is sufficient.** Edge Functions add Deno deployment complexity and cold start latency (~200ms). The trigger approach has zero extra latency and is already the pattern for attempt limiting.

**Trigger alone is sufficient when:**
- Runs are inserted directly via `sb.from('runs').insert()`
- The trigger rejects invalid inserts with a thrown exception
- The client surfaces the error as "scoring has closed"

**Add Edge Functions when:**
- Server-side score validation is needed (replay verification)
- Rate limiting beyond DB-level attempt counts
- Webhooks to external services (Discord alerts, email notifications) on run submission

**Auto-transition from `live` → `ended`:** Without pg_cron (free tier limitation), the cleanest approach is to check in the trigger:

```sql
-- In before_run_insert, after fetching event status:
IF v_event_status = 'live' AND now() > v_event_ends THEN
  UPDATE public.weeks SET status = 'ended', ended_at = now()
  WHERE id = NEW.week_id;
  RAISE EXCEPTION 'event_cutoff_passed';
END IF;
```

This lazily transitions the event to `ended` on the first attempted run after cutoff. The admin panel's event list query will pick up the new status. The alternative is polling from `gameshow-client.js` every 60 seconds and calling an RPC — acceptable for v1 but the trigger is cleaner.

**Confidence:** HIGH — DB trigger enforcement of insert conditions is well-established Supabase/Postgres pattern. Edge Function details (Deno runtime, cold starts) based on training knowledge (August 2025 cutoff); verify current cold start times in Supabase docs before committing to Edge Functions for latency-sensitive paths.

---

## Build Order Implications

The architecture above has a specific dependency order that should drive milestone sequencing:

### Phase 1 must establish: Event system DB changes

Everything downstream depends on `weeks` having `status` and `event_type`. This migration must land before any game wiring, admin UI, or age gating work begins. A partial schema causes cascading rework.

- Add `status`, `event_type`, `published_at`, `ended_at` to `weeks`
- Add age_verifications table
- Add `competition_eligible` and `is_practice` columns
- Update `before_run_insert` trigger for status gating
- Update `weeks_select_all` → `weeks_select_published` RLS policy

### Phase 2 can parallelize: `gameshow-client.js` + admin event controls

Once the DB schema is stable, `gameshow-client.js` (shared client module) and the admin publish flow are independent workstreams that don't block each other.

### Phase 3 depends on both: Game 02 integration

Fish Stack can only integrate with the event system once `gameshow-client.js` exists with the `init({ gameSlug })` API. Attempting to integrate Game 02 before the shared client module exists forces Game 02 to duplicate the penguin game's Supabase wiring — and then requires a refactor.

### Phase 4 is independent: Profile / age verification UI

The `age_verifications` table and trigger can be built and tested independently of game integration. The profile page (`/profile`) is a standalone HTML file that reads auth state and presents the verification form.

### The HUD shell wall: don't build `/profile` route until HUD can link to it

`hud.js` currently has a menu button with no routing. The profile page is only useful once the HUD menu can navigate to it. Either build `GameshowHud.onMenuClick()` routing in the same phase as the profile page, or accept that `/profile` is initially accessible only via direct URL.

### Key constraint: `gameshow-client.js` before Fish Stack

The single highest-leverage architectural decision is extracting `gameshow-client.js` before building Game 02. If Fish Stack is built before this module exists, you will have two copies of the auth + event + submission logic diverging from the start. That technical debt compounds with every additional game.

---

## Component Boundaries Summary

| Component | File(s) | Owns | Does NOT own |
|-----------|---------|------|--------------|
| Game shell | `penguin-game.html`, `fish-stack.html` | Rendering, game logic, input handling | Auth, Supabase, event state |
| HUD overlay | `hud.js` / `hud.css` | Visual HUD display, countdown, attempt dots | Data fetching, game logic |
| Gameshow client | `gameshow-client.js` (new) | Supabase init, auth, event fetch, run submit, eligibility | Game rendering, HUD rendering |
| Admin panel | `admin.html` | Event CRUD, status transitions, winner view | Player-facing UI |
| Profile page | `profile.html` (new) | Age verification form, display name, auth | Gameplay |
| Leaderboard page | `leaderboard.html` (new) | Public leaderboard view, event history | Auth, gameplay |
| DB layer | `supabase/` | Data integrity, attempt limiting, rank computation, cutoff enforcement | Business UI logic |
