# MiniGameshow — Cursor Roadmap
*Last updated: 2026-04-03*

---

## Game Show shell vs competition game

Two layers — keep them separate in code and in conversation:

| **Game Show shell** | **Competition game** |
|---------------------|----------------------|
| Brand, schedule copy, prize framing in the **title / post-run cards** | Canvas loop, obstacles, input, daily seed, local run state |
| Top HUD bar ([`hud.js`](prototypes/hud.js)), hamburger menu (leaderboard, account, share), auth entry points | Score, fish/combo UI on canvas, game-over flow, `runs` insert |
| “What week is it, can I still score, who am I?” | “What happened this run; practice vs competing?” |

The **shell is reused every week**; the **game swaps** (Pengu Fisher today, Fish Stack tomorrow) while Supabase events, attempts, and leaderboard stay the same contract.

**Where it lives today:** shell chrome + overlay markup mostly in [`prototypes/penguin-game.html`](prototypes/penguin-game.html) (Zones 1–3) + [`prototypes/hud.js`](prototypes/hud.js); the arcade layer is the canvas + game loop in the same HTML file until we split it.

---

## What This Product Is

A mobile-first web game show. Players tap a link, play a simple arcade game (5 attempts/day), and compete for a real weekly prize. No app install. A live Sunday stream crowns the weekly champion.

**The core loop:**
- Monday: new game drops, link goes live, social posts go out
- Tue–Sat: players get 5 attempts/day, leaderboard updates live
- Saturday midnight: scoring closes (enforced server-side)
- Sunday: live stream crowns champion, new game goes live immediately after

**The design rules that never change:**
- 5 attempts per day is a feature, not a restriction
- Zero friction — tap link, playing within 10 seconds, no install
- Never pay-to-win, never stressful, never dark
- Phone first — design starts at 375px width
- Vanilla JS only — no framework, no build step

---

## The Codebase Right Now

```
prototypes/penguin-game.html     ← the entire game (~3,400 lines, single file)
prototypes/hud.js                ← the top bar HUD (prize, countdown, rank, avatar, menu)
prototypes/hud.css               ← HUD styles
prototypes/admin.html            ← operator admin panel (create/manage events)
prototypes/supabase-config.js    ← your Supabase URL + anon key (gitignored, not in repo)
supabase/schema.sql              ← full database schema
supabase/migrations/             ← migration files applied to Supabase
prototypes/assets/               ← sprites, icons, sticker images
GAME_BIBLE.md                    ← full creative/design reference (characters, games, tone)
```

**Supabase tables:**
- `profiles` — user accounts: id, username, display_name, is_18_plus, is_admin, is_banned
- `weeks` — competition events: name, prize, start/end times, game selection
- `runs` — every score submitted with event reference, day seed, gameplay data
- `daily_attempts` — enforces the 5-attempts-per-day limit per user per seed
- `leaderboard` — ranked scores view

---

## What's Already Built

### ✅ Phase 1 — Phone Shell & PWA (complete)
- Game renders full-screen on mobile with no horizontal scroll
- JUMP and CAST thumb buttons sized for thumbs (44×44px minimum)
- Safe-area insets for notched phones (iPhone X+)
- PWA manifest — installable from browser, no app store
- Supabase JS pinned to specific CDN version

### ✅ Phase 2 — Auth & Player Profiles (complete, needs repair)
- Signup with display name + age checkbox (18+)
- Session persists across browser refreshes
- Forgot password / email reset flow
- Account tab: avatar circle, display name, age badge, sign out
- Under-18 users get `playMode='practice'` with amber indicator — scores save but stay on under-18 leaderboard only
- Leaderboard shows display name (not email)
- DB migration: `profiles` table has `display_name` and `is_18_plus` columns

---

## 🔧 Repair List (Do These First)

These are known issues from today's session that need fixing before moving forward:

### 1. Desktop layout — shell background
**File:** `prototypes/penguin-game.html`
**Status:** **Resolved.** `#shell` uses dark `#110822` again; cream/sunburst stay on the title overlay only. A short comment above `#shell` explains why (letterboxing on desktop).
**CSS selector:** `#shell` in the `<style>` block.

### 2. Welcome sticker image
**File:** `prototypes/penguin-game.html`
**Problem:** The sticker `src` was originally pointing to `assets/PLAY-TO-WIN.png` which is a 2752×1536 landscape image (4MB) that doesn't fit the square sticker shape.
**Current state:** Already updated today to use `assets/PLAY-TO-WIN_1.png` (200×200px, correct).
**Sticker position:** Also updated today — sticker sits at `top:0` of the card, centered horizontally, with `transform:translate(-50%,-50%)` so it's half above/half below the card's top edge. Card has `padding-top:88px` so prize content shows below it.
**Status:** Visually fixed but needs real-device testing.

### 3. Auth flow — end-to-end test needed
**Problem:** The entire auth system (signup, signin, forgot password, age gating, account tab) was built by AI agents and never manually tested end-to-end.
**What to test:**
- Sign up with display name + email + password + age checkbox checked → account created, display name on leaderboard, shows "Competitor" badge
- Sign up with age checkbox UNCHECKED → account created, practice mode amber banner appears, account tab shows "Practice Mode" badge
- Sign out → practice notice hides, state resets to guest
- Sign in on a different browser → session restores
- Forgot password → reset email arrives, link opens new-password form, password updates successfully
- Leaderboard shows display name not email

### 4. Supabase migration — run on your project
**File:** `supabase/migrations/20260403_add_display_name_is_18_plus.sql`
**Problem:** The migration file exists locally but may not have been applied to your Supabase project yet.
**Fix:** Run it via Supabase CLI (`supabase db push`) or paste it in the SQL editor in the Supabase dashboard.

---

## What's Next — Remaining Phases

### Phase 3 — Event System & Admin Controls
**Goal:** An operator (you) can create and manage a competition event. Everything in the game responds to the active event.

**What to build:**
1. **Event CRUD in admin panel** — create/edit/delete events with: game selection, event name, optional prize text, start datetime, end datetime, test/internal flag. Admin panel must be behind `is_admin = true` check.
2. **Server-side cutoff enforcement** — a Postgres trigger rejects any run inserted after `weeks.ends_at`. Player sees "Scoring closed" message.
3. **One active event at a time** — DB constraint prevents two overlapping active events.
4. **HUD event awareness** — HUD shows active event name, prize, and countdown to Saturday cutoff. Correct state when no event is active.
5. **Post-event admin view** — frozen leaderboard after event ends with winner (#1 on 18+ board) highlighted. Manual "new event live" trigger button for post-show.
6. **Player ban controls** — admin can ban a player; their score submissions are blocked at DB level.

**Done when:** Admin can create an event, game shows the prize and countdown, scoring closes automatically at the deadline, and admin can see the winner.

---

### Phase 4 — Gameplay Polish, Leaderboard & Security
**Goal:** The full competitive loop is production-ready and hardened.

**What to build:**
1. **Attempt dots accuracy** — HUD attempt dots always match `daily_attempts` in DB, including after page refresh and next-day reset.
2. **Game-over screen** — shows run score, personal best, remaining attempts today, current leaderboard rank. All within 2 seconds of run ending.
3. **Leaderboard panel** — two views: 18+ competitors and under-18 practice. Fetch on panel open. Freeze display after event cutoff.
4. **Score validation** — each run submission includes a gameplay hash (input count, session duration, day seed match). Runs that don't pass are flagged `is_validated = false` in the DB. Not blocked — flagged for review.
5. **RLS verification** — confirm a score submitted without a valid auth JWT is rejected by Supabase row-level security.
6. **Banned player enforcement** — `is_banned = true` on profiles table blocks score inserts at DB level.

**Done when:** Attempt dots are always right, the game-over screen shows meaningful data, leaderboard has age-separated views, and basic score manipulation is flagged.

---

### Phase 5 — Score Card Sharing
**Goal:** After any run, players can share a score card that drives new players into the game with one tap.

**What to build:**
1. **Score card** — shareable image (Canvas export or styled DOM snapshot) showing: score, current rank, event name, game character. Triggered via Web Share API on mobile, fallback to clipboard copy on desktop.
2. **Open Graph tags** — `og:title`, `og:description`, `og:image` on the game page so the shared link shows a proper preview in iMessage, Twitter, Slack, etc.

**Done when:** The Share button appears after every run, the card looks good, and pasting the link anywhere shows a proper preview.

---

### Phase 6 — Fish Stack (Game 02)
**Goal:** Fish Stack is fully playable as a selectable competition game.

**Note from Game Bible:** A prototype may already exist. Check the repo for a `fish-stack.html` or similar before rebuilding.

**What to build:**
1. **Fish Stack core game** — stacking mechanic, 7 fish piece types (Salmon, Eel, Pufferfish, Herring, Tuna, Cod, Mackerel), Babs the Walrus reacting live with 5 emotional states and 30+ voice lines. Must be legible in under 10 seconds with no tutorial.
2. **Supabase integration** — score submission with gameplay hash, daily attempts, event linkage. Register `fish-stack` slug in `games` table.
3. **Admin game selection** — admin can pick Fish Stack as the event game. Leaderboard, attempts, and game-over screen all work identically to Pengu Fisher.

**Done when:** Fish Stack is playable at its own URL, fully wired to the competition system, and Babs is present with her personality intact.

---

## Characters (from Game Bible)

| Character | Role | In Game 01 | In Game 02 |
|-----------|------|-----------|-----------|
| **The Penguin** (name TBD) | Player character | Side-scroller protagonist | — |
| **Babs** (Walrus) | Elder shopkeeper, grumpy, secretly supportive | Breathing obstacle — slip under her | Reacts live to your stack, 30+ voice lines |
| **Polar Bear** (name TBD) | Charming rival | Variable speed obstacle | — |
| **Seal** (name TBD) | Comic relief, chaos energy | Lunging obstacle with telegraph warning | — |
| **Narwhal** (name TBD) | Mysterious, ancient, rarely seen | Appears during frenzy/bonus events | Deep Dive (Game 03) |

*Names are TBD — a design/naming session is planned before public launch.*

---

## Known Future Work (Not Scheduled Yet)

- **Game 03: Deep Dive** — Narwhal, underwater world, breath mechanic (fully designed in Game Bible)
- **Character voiceover** — Babs' lines get actual voice acting
- **Geo/age restriction framework** — structure for legal compliance in different regions
- **Winner announcement flow** — post-show UX for the champion reveal
- **Score card OG image generation** — server-side image for richer social previews
- **Naming/design session** — finalize character names before public launch

---

## How to Use This Doc in Cursor

Paste the relevant section at the start of your Cursor session. The **Repair List** is where to start. After repairs are done and tested on a real phone, move to Phase 3.

For creative/design questions (character behavior, tone, game mechanics) → refer to `GAME_BIBLE.md`.
For code structure questions → the entire game is in `prototypes/penguin-game.html`.
