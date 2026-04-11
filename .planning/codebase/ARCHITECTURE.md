# Architecture

**Analysis Date:** 2026-04-02

## Pattern Overview

**Overall:** Single-file client prototype with serverless Postgres backend (no application server)

**Key Characteristics:**
- No build pipeline for game logic — HTML files are the deployable artifacts
- All game state lives in plain JavaScript variables within a single `<script>` block inside `prototypes/penguin-game.html`
- Backend is entirely Supabase (PostgreSQL + Auth + Row Level Security + DB triggers) — no custom API layer
- `@supabase/supabase-js` is dynamically imported from CDN at runtime, not bundled
- The only build step (`npm run build`) is a Node.js script that injects Supabase credentials into `prototypes/supabase-config.js` for Vercel deployment

---

## Layers

**Gameshow HUD (Shared UI Component):**
- Purpose: Fixed top bar shown across all games — displays show title, scoring countdown, rank, best score, attempt dots, avatar, hamburger menu
- Location: `prototypes/hud.js`, `prototypes/hud.css`
- Contains: Self-contained IIFE module (`GameshowHud`) exported to `window.GameshowHud`
- Depends on: Nothing (no external deps); consumes week data pushed in by game scripts
- Used by: Every game HTML file — mounted via `<div id="gameshow-hud-mount"></div>` + `GameshowHud.init('#gameshow-hud-mount')`
- Public API: `init`, `setPrize`, `setShowAt`, `setScoringEndsAt`, `setStats`, `setPlayer`, `onMenuClick`, `onAvatarClick`, `height`

**Game Layer (Pengu Fisher):**
- Purpose: Full game loop, canvas rendering, input handling, score submission, auth UI
- Location: `prototypes/penguin-game.html` (inline `<script>` starting at line ~1136)
- Contains: All game logic — state machine, physics, terrain, obstacles, fishing mechanic, frenzy/combo systems, seeded RNG, Web Audio SFX, post-run panel, leaderboard panel, auth panel
- Depends on: `window.GameshowHud`, `window._miniGameshowSb` (Supabase client), `window.__MINIGAMESHOW_SUPABASE__` (config)
- Used by: Served as root route via Vercel rewrite (`/` → `/penguin-game.html`)

**Menu / Shell Panel (Zone 2):**
- Purpose: Slide-over panel with Leaderboard, My Scores, Account, Share tabs
- Location: Inline in `prototypes/penguin-game.html` (DOM: `#gsp-root`, logic: `openGsp`, `closeGsp`, `setGspTab`, `refreshGspLeaderboard`, `refreshGspMyScores`, `refreshGspAccount`)
- Contains: Tab-switching UI, live leaderboard fetch, user run history, account/sign-in controls
- Depends on: `window._miniGameshowSb`, `weekId` game variable

**Admin Panel:**
- Purpose: Operator interface for creating and editing competition weeks
- Location: `prototypes/admin.html`
- Contains: Auth gate (must be `is_admin = true` in `profiles`), week management table, create/edit/delete week form with auto-generated week codes and scheduling defaults, live HUD strip preview
- Depends on: `window.__MINIGAMESHOW_SUPABASE__`, `@supabase/supabase-js` from CDN

**Database (Supabase / PostgreSQL):**
- Purpose: All persistence — users, games, competition weeks, runs, leaderboard, daily attempt tracking, content events
- Location: `supabase/schema.sql`, `supabase/migrations/`
- Contains: 7 tables, RLS policies, 5 stored functions, 5 triggers

**Config Injection (Build Script):**
- Purpose: Write `prototypes/supabase-config.js` from Vercel environment variables so credentials never get committed
- Location: `scripts/vercel-write-supabase-config.mjs`
- Depends on: `SUPABASE_URL`, `SUPABASE_ANON_KEY` env vars

---

## Database Schema — All 7 Tables

**`public.games`:**
- Columns: `id uuid PK`, `slug text UNIQUE NOT NULL`, `name text NOT NULL`, `created_at timestamptz`
- Purpose: Game catalog; single seeded row `slug='pengu-fisher'`
- Relationships: Referenced by `weeks.game_id`

**`public.profiles`:**
- Columns: `id uuid PK → auth.users`, `username text UNIQUE`, `phone text`, `phone_verified bool`, `country text`, `is_banned bool`, `is_admin bool`, `created_at`, `updated_at`
- Purpose: Extends `auth.users`; `is_admin` gates admin panel; `is_banned` allows moderation
- Index: `profiles_username_lower_idx` on `lower(username)`
- Trigger: `profiles_set_updated_at` (BEFORE UPDATE) → `set_updated_at()`; `on_auth_user_created` (AFTER INSERT on `auth.users`) → `handle_new_user()`

**`public.weeks`:**
- Columns: `id uuid PK`, `week_code text UNIQUE` (e.g., `2026-W13`), `game_id uuid → games`, `seed bigint`, `starts_at timestamptz`, `ends_at timestamptz`, `prize_title text`, `sponsor_name text`, `show_at timestamptz`, `show_url text`, `prize_description text`
- Purpose: Competition window definition; `starts_at`/`ends_at` define the scoring window; `show_at` is the live broadcast time
- Constraint: `ends_at > starts_at`
- RLS: Public SELECT; INSERT/UPDATE restricted to `is_admin = true` users

**`public.runs`:**
- Columns: `id uuid PK`, `user_id uuid → profiles`, `week_id uuid → weeks`, `score bigint ≥ 0`, `attempt_num smallint 1–5`, `duration_ms int ≥ 0`, `day_seed int`, `input_count int`, `input_log jsonb`, `frame_checkpoints jsonb`, `game_version text`, `replay_payload jsonb`, `is_validated bool`, `created_at`
- Purpose: Raw score submissions with anti-cheat payload; each row is one completed run
- Triggers: `runs_before_insert` (BEFORE INSERT) → `before_run_insert()`; `runs_after_insert` (AFTER INSERT) → `after_run_insert()`; `runs_after_delete` (AFTER DELETE) → `after_run_delete()`
- Indexes: `runs_user_week_idx`, `runs_week_score_idx` (DESC), `runs_day_seed_idx`

**`public.leaderboard`:**
- Columns: `user_id uuid → profiles`, `week_id uuid → weeks` (composite PK), `best_score bigint`, `best_run_id uuid → runs`, `rank int`, `updated_at`
- Purpose: Materialized best-score cache — one row per (user, week); avoids full `runs` scan for rank display
- Indexes: `leaderboard_week_rank_idx`, `leaderboard_week_score_idx` (DESC)
- Updated by: `after_run_insert` trigger (upsert on new personal best); `after_run_delete` trigger (recompute on run deletion)

**`public.daily_attempts`:**
- Columns: `user_id uuid → profiles`, `day_seed int` (composite PK), `attempts_used smallint 0–5`, `updated_at`
- Purpose: Enforces 5 attempts per calendar day per user; `day_seed` is derived from the UTC calendar date
- Updated by: `before_run_insert` (increment with `FOR UPDATE` lock); `after_run_delete` (decrement)

**`public.content_events`:**
- Columns: `id uuid PK`, `event_type text`, `metadata jsonb`, `created_at`
- Purpose: Append-only event log for async social/notification pipeline
- Events written: `run_submitted`, `new_high_score` (by `after_run_insert`)
- RLS: No client access — written only by `SECURITY DEFINER` triggers

---

## Database Triggers and Functions

**`before_run_insert()` (BEFORE INSERT on `runs`):**
- Validates `user_id = auth.uid()` for direct client inserts
- Upserts `daily_attempts` row, acquires `FOR UPDATE` row lock, enforces ≤5 attempts/day
- Sets `NEW.attempt_num` to the incremented count

**`after_run_insert()` (AFTER INSERT on `runs`):**
- Upserts `leaderboard` if `NEW.score > v_old_best`
- Calls `refresh_leaderboard_ranks(week_id)` — recomputes all rank values for the week using `row_number() OVER (ORDER BY best_score DESC, updated_at ASC)`
- Writes `run_submitted` event to `content_events`
- Writes `new_high_score` event to `content_events` if score improved

**`after_run_delete()` (AFTER DELETE on `runs`):**
- Decrements `daily_attempts.attempts_used`
- If deleted run was the `best_run_id`, finds next best run and updates leaderboard (or removes row if no runs remain)
- Calls `refresh_leaderboard_ranks(week_id)`

**`handle_new_user()` (AFTER INSERT on `auth.users`):**
- Creates `public.profiles` row with `id` matching the new auth user

**`set_updated_at()` (BEFORE UPDATE on `profiles`):**
- Sets `NEW.updated_at = now()`

---

## Data Flow

**Player load (first visit):**

1. Browser loads `penguin-game.html` → `supabase-config.js` sets `window.__MINIGAMESHOW_SUPABASE__`
2. `hud.js` sets `window.GameshowHud`; game script boots
3. `bootSupabaseAuth()` dynamically imports `@supabase/supabase-js` from CDN; initializes Supabase client into `window._miniGameshowSb`
4. Supabase checks persisted session → calls `onSignedIn(session)` or `updateAuthUI(null)`
5. `fetchActiveEvent()` (or equivalent) queries the active **`public.events`** row → pushes prize + scheduling into `GameshowHud`
6. If signed in: `fetchAttemptsAndSetMode(userId)` queries `public.daily_attempts` → sets `playMode` (`competing` | `freeplay`)
7. `fetchUserRank(userId)` derives rank from **`public.runs`** for the active event (global ordering: score desc, `created_at` asc; rank = count of strictly better runs + 1) → updates HUD stats (`best_score` = that run’s score)

**Score submission:**

1. Game loop detects lives = 0 → sets `state = 'dead'` → calls `submitRunToSupabase()`
2. Validates signed-in session and active event window (client checks `public.events` / `event_id`)
3. Inserts row into `public.runs` (includes `score`, `day_seed`, `input_count`, `game_version`, `replay_payload`)
4. Database `runs_before_insert` trigger: validates `user_id = auth.uid()`, increments `daily_attempts`, sets `attempt_num`, enforces 5/day cap
5. Database `runs_after_insert` trigger: upserts `leaderboard` best score, recalculates all ranks via `refresh_leaderboard_ranks()`, writes two `content_events` rows (`run_submitted` and optionally `new_high_score`)
6. Client re-fetches `daily_attempts` and run-ordered rank (from `runs`) → updates HUD and overlay (`leaderboard` may still be updated by DB triggers for other paths)

**Auth state change:**

- `sb.auth.onAuthStateChange` fires on sign-in/sign-out → `onSignedIn` or `onSignedOut`
- `document.visibilitychange` (tab return) also refreshes competition state
- Profile row auto-created by `on_auth_user_created` trigger on `auth.users`

---

## State Management

**Game state** is plain module-scope variables in `penguin-game.html`:

| Variable | Type | Purpose |
|---|---|---|
| `state` | `'title' \| 'playing' \| 'dead' \| 'gameover'` | Primary game-screen state machine |
| `playMode` | `'guest' \| 'competing' \| 'freeplay'` | Determines seed source and whether scores are saved |
| `score`, `hiScore`, `fishCount`, `lives` | number | In-run counters |
| `combo`, `comboTimer`, `fishMeter`, `frenzyActive` | number/bool | Scoring multiplier systems |
| `currentSeed` | number | Active RNG seed (daily seed for competing, random otherwise) |
| `rng` | function | Seeded LCG PRNG (`(s * 1664525 + 1013904223) >>> 0`); re-initialized on each `resetGame()` |
| `weekId`, `weekPrize`, `weekShowAt`, `weekEndsAt` | varies | Active week data fetched from DB |
| `attemptsUsed` | number | Fetched from `daily_attempts`, tracked locally |
| `playerName` | string | `profiles.username` or email prefix |

**Play mode state transitions:**

```
guest ──sign in──▶ competing ──5 attempts used──▶ freeplay
  ▲                    │                               │
  └───────sign out──────┴───────────sign out───────────┘
```

**HUD state** is internal to the `GameshowHud` IIFE module in `hud.js` — only updated via the public API.

**No reactive framework, no shared stores.** State mutation is imperative. UI is updated by direct DOM manipulation after each state change.

---

## Key Abstractions

**`GameshowHud` module:**
- Purpose: Decoupled, reusable top bar that any game HTML can mount
- Location: `prototypes/hud.js`
- Pattern: IIFE returning a public API object; assigned to `window.GameshowHud`

**Seeded RNG (`makeRng`):**
- Purpose: Ensures all players see the same obstacle/fish sequence on the same day
- Location: `prototypes/penguin-game.html` line ~1246
- Pattern: LCG (`(s * 1664525 + 1013904223) >>> 0`); `rng` is reassigned at `resetGame()` using `currentSeed`; `dailySeed` derived from `Math.floor(Date.UTC(y, m, d) / 86400000)`

**`cfg()` difficulty function:**
- Purpose: Returns all difficulty parameters as a function of `distance` (units traveled), so difficulty escalates continuously
- Location: `prototypes/penguin-game.html` line ~1332
- Pattern: Pure function called each frame/update; controls `speed`, `sealLunge`, `polarbear`, `crackIce`, `fishRate`, `obstacleGap`, `biteSpeed`, `castWindow`, `comboDecay`

**Database triggers as business logic:**
- Purpose: Enforce attempt limits, maintain leaderboard, emit content events — entirely in PostgreSQL, not client
- Location: `supabase/schema.sql` — `before_run_insert`, `after_run_insert`, `after_run_delete`, `on_auth_user_created`
- Pattern: `SECURITY DEFINER` plpgsql functions; `before_run_insert` uses `FOR UPDATE` row lock on `daily_attempts` to prevent race conditions

---

## Entry Points

**Game (player-facing):**
- Location: `prototypes/penguin-game.html`
- Triggers: Served at `/` via Vercel rewrite in `vercel.json`
- Responsibilities: Entire game — canvas, audio, auth, score submission, leaderboard display

**Admin panel:**
- Location: `prototypes/admin.html`
- Triggers: Served at `/admin.html`; requires `is_admin = true` on `profiles` row
- Responsibilities: Create/edit/delete competition `weeks` rows; live preview of HUD schedule line

**Build entry point:**
- Location: `scripts/vercel-write-supabase-config.mjs`
- Triggers: `npm run build` (called by Vercel pre-deployment)
- Responsibilities: Write `prototypes/supabase-config.js` from env vars

---

## Overlay / Screen Architecture

The game uses a layered Z-order system within a single HTML page:

| Layer | Element | Z-index | Role |
|---|---|---|---|
| Gameshow HUD | `#gameshow-hud` | 260 | Fixed top bar — always visible |
| Game shell | `#shell` | — | Full-screen canvas area below HUD |
| Canvas | `#gameCanvas` | — | Game rendering |
| In-canvas metrics | `#top-bar` | 10 | Score/combo/frenzy floats over canvas |
| Game overlay | `#overlay` | 20 | Title / game-over card covers canvas |
| Menu panel | `#gsp-root` | (covers shell) | Slide-over tabs: Leaderboard, My scores, Account, Share |

`#overlay` has two sub-states controlled by `data-zone` on `#ov-card`:
- `data-zone="title"` — welcome card (first-play / between runs); includes auth embed, prize display, attempt dots
- `data-zone="gameover"` — post-run card (score, rank, play-again, share)

---

## Error Handling

**Strategy:** Silent degradation — no Supabase config causes UI to show a reminder message; failed DB operations show inline error text; game always remains playable as guest even if all network calls fail.

**Patterns:**
- All async Supabase calls wrapped in `try/catch`; errors logged to console via `console.error('tag', e)`, non-blocking UI message shown where applicable
- Missing `supabase-config.js` detected by checking `window.__MINIGAMESHOW_SUPABASE__` at boot; sign-in buttons disabled with `aria-disabled`
- DB trigger failures surface as `insErr.message` displayed in the post-run tip area (`#postrun-tip`)
- `GameshowHud` stubbed out with no-op functions if `hud.js` fails to load (safety stub in `prototypes/penguin-game.html` line ~1139)

---

## Cross-Cutting Concerns

**Audio:** Web Audio API oscillator synthesis — no audio files. iOS excluded from vibration. Context created lazily on first gesture.

**Canvas sizing:** `resizeCanvas()` maintains a 2:1 (660×330) native resolution, scaled via CSS to fill the viewport below the HUD. Overlay and controls are repositioned to match canvas pixel position. Called on `resize`, `orientationchange`, and `document.fonts.ready`.

**Mobile PWA:** `<meta name="apple-mobile-web-app-capable">` set; `touch-action: manipulation` applied globally to suppress double-tap zoom; `env(safe-area-inset-bottom)` used in controls padding.

**Credentials:** `prototypes/supabase-config.js` is gitignored. Vercel writes it at build time from environment variables. The anon key (public-safe) is the only credential ever written to this file — service role key is never used client-side.

---

*Architecture analysis: 2026-04-02*
