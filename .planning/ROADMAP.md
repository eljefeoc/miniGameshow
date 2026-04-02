# Roadmap: miniGameshow

**Milestone:** v1.0 — Launch-Ready Game Show Platform
**Granularity:** Standard
**Generated:** 2026-04-02

---

## Phase Overview

| Phase | Name | Goal | Plans | Requirements |
|-------|------|------|-------|--------------|
| 1 | Phone-First Shell & PWA | 3/3 | Complete   | 2026-04-02 |
| 2 | Auth & Player Profiles | Players can create verified accounts with age declaration, enabling prize-eligible competition | 3 | AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06 |
| 3 | Event System & Admin Controls | An operator can create, run, and close a competition event; everything downstream is event-aware | 4 | EVNT-01, EVNT-02, EVNT-03, EVNT-04, EVNT-05, EVNT-06, EVNT-07, ADMN-01, ADMN-02, ADMN-03, ADMN-04, ADMN-05, ADMN-06 |
| 4 | Gameplay Polish, Leaderboard & Security | The full competitive loop is hardened — scores are validated, leaderboard is accurate, banned players are blocked | 4 | GAME-01, GAME-02, GAME-03, GAME-04, GAME-05, LBRD-01, LBRD-02, LBRD-03, LBRD-04, SECU-01, SECU-02, SECU-03, SECU-04 |
| 5 | Social & Sharing | Players can share score cards that drive new players to the game via a single link | 2 | SOCL-01, SOCL-02, SOCL-03 |
| 6 | Game 02: Fish Stack | Fish Stack is fully playable as a selectable event game with Supabase integration and Babs character | 3 | GAME-06 |

---

## Phase 1: Phone-First Shell & PWA

**Goal:** The game is fully playable on a real phone — full-viewport, touch-optimized, no horizontal scroll — and installable from the browser without requiring an app store.

**Requirements covered:** SHEL-01, SHEL-02, SHEL-03, SHEL-04, SHEL-05

**Plans:**
3/3 plans complete
2. Touch target audit & interaction polish — verify all tap targets meet 44×44px minimum, ensure tap-to-play works reliably, suppress double-tap zoom, apply safe-area insets for notched phones
3. PWA manifest & load performance — add `manifest.json` with icon and theme color, pin Supabase JS CDN to a specific version (addresses SECU-03 / CONCERNS.md CDN risk), audit asset loading order to hit sub-3-second interactive on LTE

**Done when:**
- [ ] Game renders without horizontal scrolling on a physical 375px-wide phone screen (iOS Safari + Android Chrome verified)
- [ ] All interactive controls are tap-able with a thumb; no tap accidentally hits an adjacent element
- [ ] Lighthouse or manual LTE throttle confirms interactive within 3 seconds on a mid-range device
- [ ] `manifest.json` is present; browser shows "Add to Home Screen" prompt; game launches full-screen from home screen
- [ ] Portrait and landscape both render usably; layout does not break on orientation change

---

## Phase 2: Auth & Player Profiles

**Goal:** Players can create an account, declare their age, and log back in across sessions — establishing the identity layer that gates prize eligibility and separates 18+ competitors from under-18 practice players.

**Requirements covered:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06

**Plans:**
1. Signup & session polish — clean up the existing email/password signup flow, add display name field and age declaration (18+ checkbox) to the signup form, persist session across browser refresh
2. Password reset & account management — implement the "forgot password" email link flow via Supabase Auth; add a basic account tab in the menu panel showing display name and age tier
3. Age-gated play modes — wire `is_18_plus` (or equivalent profile flag) to the play mode state machine: 18+ users compete on the main leaderboard; under-18 users are placed in practice mode with a separate leaderboard and cannot win prizes

**Done when:**
- [ ] A new user can sign up with email, password, display name, and an age declaration in a single flow
- [ ] Signing in on a different browser or after refresh restores the authenticated session without re-prompting
- [ ] "Forgot password" sends a reset email and the link successfully updates the password
- [ ] Under-18 players see a "Practice Mode" indicator and their scores do not appear on the 18+ competitive leaderboard
- [ ] A player's display name (not email) is what appears on the leaderboard

---

## Phase 3: Event System & Admin Controls

**Goal:** An operator can create a competition event with a game, time window, and optional prize; the game responds to the active event; and the operator can surface the winner after the event closes.

**Requirements covered:** EVNT-01, EVNT-02, EVNT-03, EVNT-04, EVNT-05, EVNT-06, EVNT-07, ADMN-01, ADMN-02, ADMN-03, ADMN-04, ADMN-05, ADMN-06

**Plans:**
1. Event data model & admin CRUD — extend or confirm the `weeks` table covers event name, game selection, start/end time, optional prize field, and test/internal flag; build admin create/edit/delete event forms with validation; harden admin panel behind `is_admin = true` check
2. Active event enforcement — enforce one-active-event-at-a-time constraint; wire `EVNT-05` server-side cutoff (runs submitted after `ends_at` are rejected by DB trigger); implement `EVNT-07` "scoring closed" state visible to players after event ends
3. HUD event awareness — connect HUD to active event data (event name, prize, countdown); update `fetchActiveWeek()` to read event name and prize from the events table; show correct state when no event is active
4. Admin winner surface & moderation tools — implement frozen leaderboard view in admin after event ends with winner (#1 on 18+ board) prominently identified; add "new event live" manual trigger (`ADMN-03`); add player ban controls (`ADMN-05`) and admin dashboard summary (`ADMN-06`)

**Done when:**
- [ ] Admin can create an event with game, name, start/end time, and optional prize; it appears immediately in the game HUD
- [ ] A test event (no prize) does not trigger any public winner announcement path
- [ ] A run submitted 1 second after `ends_at` is rejected by the database; the player sees a "scoring closed" message
- [ ] Only one event can be active at a time; attempting to create a second active event is blocked
- [ ] After an event ends, the admin panel shows the frozen leaderboard with the #1 player clearly identified
- [ ] Admin can ban a player; subsequent score submissions from that player are blocked (SECU-04 dependency addressed here at the data model level)
- [ ] Admin dashboard shows active event name, player count, and top 3 scores at a glance

---

## Phase 4: Gameplay Polish, Leaderboard & Security

**Goal:** The full competitive loop is production-ready — attempt dots are accurate, the game-over screen shows meaningful context, the leaderboard correctly separates age tiers, and scores are protected against trivial manipulation.

**Requirements covered:** GAME-01, GAME-02, GAME-03, GAME-04, GAME-05, LBRD-01, LBRD-02, LBRD-03, LBRD-04, SECU-01, SECU-02, SECU-03, SECU-04

**Plans:**
1. Score submission & event linkage — ensure every run insert includes the active event (`week_id`) reference; confirm existing RLS JWT enforcement (SECU-01); implement gameplay hash on score submission (input count, duration, day seed match) as the SECU-02 anti-cheat payload; enforce `is_banned` check on insert so banned players' submissions are rejected at DB level
2. HUD & attempt dot accuracy — verify attempt dots reflect `daily_attempts` in real time; confirm `GAME-01` 5/day limit is correctly surfaced in the UI after each run including edge cases (refresh mid-session, returning to game next day)
3. Game-over screen & rank display — build out the post-run card with: run score, personal best, remaining attempts, current leaderboard rank (GAME-05); ensure HUD shows live rank during active event (LBRD-02)
4. Leaderboard panel — implement leaderboard panel with separate 18+ and under-18 views (LBRD-03); fetch on panel open (LBRD-01); implement leaderboard freeze display at event cutoff (LBRD-04)

**Done when:**
- [ ] Attempt dots in the HUD always match the `daily_attempts` count in the database, including after refresh and next-day reset
- [ ] The game-over screen shows run score, personal best, remaining attempts today, and current rank within 2 seconds of run ending
- [ ] A score submitted without a valid auth JWT is rejected by Supabase RLS (verifiable via browser devtools with token stripped)
- [ ] A run with a mismatched gameplay hash (e.g., impossible input count for the score) is flagged in the `is_validated` column on the `runs` row
- [ ] The leaderboard panel has two views: 18+ competitors and under-18 practice; scores do not appear in the wrong view
- [ ] After event cutoff, the player-facing leaderboard shows a frozen state; no new scores appear even if submitted
- [ ] A banned player's score submission is rejected and they see an appropriate message

---

## Phase 5: Social & Sharing

**Goal:** After any run, a player can share a score card that drives new players directly into the game with a single tap and no friction.

**Requirements covered:** SOCL-01, SOCL-02, SOCL-03

**Plans:**
1. Score card generation — build a shareable score card (PNG via Canvas export or a styled DOM node) showing score, current rank, event name, and game character; trigger via native Web Share API with fallback to clipboard copy
2. OG meta tags & link routing — add Open Graph meta tags (title, description, image) to the game page so social previews render correctly when the link is shared; confirm shared link opens directly to game with no redirect friction

**Done when:**
- [ ] After any run, the game-over screen has a Share button that invokes the native share sheet on mobile (or copies link on desktop)
- [ ] The shared image shows the player's score, rank, and event name — no placeholder or broken image
- [ ] Pasting the shared link into iMessage, Twitter, or Slack shows a proper OG preview (title, description, image)
- [ ] Tapping the shared link on a phone opens the game directly — no intermediate "open in browser" redirect, no install prompt required

---

## Phase 6: Game 02 — Fish Stack

**Goal:** Fish Stack is playable as a selectable competition game, fully wired to the event and leaderboard system, featuring the Babs character.

**Requirements covered:** GAME-06

**Plans:**
1. Fish Stack core game loop — implement Fish Stack gameplay (stacking mechanic) in a new game HTML file following the same architecture as Penguin Fisher; integrate Babs the Walrus character; ensure the game is instantly legible in under 10 seconds with no tutorial
2. Supabase & event system integration — wire Fish Stack to the shared Supabase client, score submission (with gameplay hash), daily attempts, and event linkage; register `fish-stack` slug in the `games` table; ensure HUD mounts correctly
3. Admin game selection — confirm admin event creation form can select Fish Stack as the event game; verify leaderboard, attempt tracking, and game-over screen all function identically to Penguin Fisher when Fish Stack is the active event game

**Done when:**
- [ ] Fish Stack is playable at its own route and passes the 10-second legibility test with a first-time player
- [ ] Scores from Fish Stack are saved to Supabase with correct `week_id`, `day_seed`, and gameplay hash
- [ ] An admin can create an event with Fish Stack as the selected game; players see the correct game when that event is active
- [ ] Attempt limiting, leaderboard ranking, and the game-over screen all work identically to Penguin Fisher
- [ ] Babs the Walrus character is present and visually consistent with the Arctic world tone

---

## Requirement Coverage

| Requirement | Phase |
|-------------|-------|
| SHEL-01 | Phase 1 |
| SHEL-02 | Phase 1 |
| SHEL-03 | Phase 1 |
| SHEL-04 | Phase 1 |
| SHEL-05 | Phase 1 |
| AUTH-01 | Phase 2 |
| AUTH-02 | Phase 2 |
| AUTH-03 | Phase 2 |
| AUTH-04 | Phase 2 |
| AUTH-05 | Phase 2 |
| AUTH-06 | Phase 2 |
| EVNT-01 | Phase 3 |
| EVNT-02 | Phase 3 |
| EVNT-03 | Phase 3 |
| EVNT-04 | Phase 3 |
| EVNT-05 | Phase 3 |
| EVNT-06 | Phase 3 |
| EVNT-07 | Phase 3 |
| GAME-01 | Phase 4 |
| GAME-02 | Phase 4 |
| GAME-03 | Phase 4 |
| GAME-04 | Phase 4 |
| GAME-05 | Phase 4 |
| GAME-06 | Phase 6 |
| LBRD-01 | Phase 4 |
| LBRD-02 | Phase 4 |
| LBRD-03 | Phase 4 |
| LBRD-04 | Phase 4 |
| ADMN-01 | Phase 3 |
| ADMN-02 | Phase 3 |
| ADMN-03 | Phase 3 |
| ADMN-04 | Phase 3 |
| ADMN-05 | Phase 3 |
| ADMN-06 | Phase 3 |
| SOCL-01 | Phase 5 |
| SOCL-02 | Phase 5 |
| SOCL-03 | Phase 5 |
| SECU-01 | Phase 4 |
| SECU-02 | Phase 4 |
| SECU-03 | Phase 1 |
| SECU-04 | Phase 4 |

**Total:** 34 requirements (41 rows including SECU-03 which appears in Phase 1 and is confirmed in Phase 4) across 6 phases. All covered.

> Note: SECU-03 (pin Supabase JS CDN to a specific version) is addressed in Phase 1 Plan 3 as part of load performance work — it is a prerequisite for security throughout the project. SECU-04 (`is_banned` enforcement) depends on the ban flag being set by admin (Phase 3, ADMN-05); enforcement on score submission is wired in Phase 4.

---

## Progress

| Phase | Status | Plans Complete |
|-------|--------|----------------|
| 1 — Phone-First Shell & PWA | Not started | 0 / 3 |
| 2 — Auth & Player Profiles | Not started | 0 / 3 |
| 3 — Event System & Admin Controls | Not started | 0 / 4 |
| 4 — Gameplay Polish, Leaderboard & Security | Not started | 0 / 4 |
| 5 — Social & Sharing | Not started | 0 / 2 |
| 6 — Game 02: Fish Stack | Not started | 0 / 3 |

---

*Roadmap generated: 2026-04-02*
*Milestone: v1.0 — Launch-Ready Game Show Platform*
