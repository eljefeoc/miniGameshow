# Requirements: miniGameshow

**Defined:** 2026-04-02
**Core Value:** Anyone who sees a link on social media can tap it and be playing within 10 seconds — zero friction from discovery to first play.

## v1 Requirements

### Shell & Mobile Experience

- [x] **SHEL-01**: Game is fully playable on a 375px-wide phone screen without horizontal scrolling
- [x] **SHEL-02**: All touch targets are at minimum 44×44px; tap-to-play works on iOS Safari and Android Chrome
- [x] **SHEL-03**: Game shell loads and is interactive within 3 seconds on mid-range phone on LTE
- [x] **SHEL-04**: App has a PWA manifest with icon and theme color (installable but no install required to play)
- [x] **SHEL-05**: Landscape and portrait orientations both work on phone; layout adapts without breaking

### Authentication & Profiles

- [x] **AUTH-01**: User can sign up with email and password (existing — needs polish)
- [x] **AUTH-02**: User can sign in and session persists across browser refresh
- [x] **AUTH-03**: User can reset password via email link
- [x] **AUTH-04**: User sets a display name during signup (shown on leaderboard)
- [x] **AUTH-05**: User declares age (18+) during signup; stored on profile; gates prize eligibility
- [x] **AUTH-06**: Users under 18 can play but are placed in a separate practice leaderboard, cannot win prizes

### Event System

- [ ] **EVNT-01**: Admin can create an event with: game selection, start time, end time, prize description (optional), event name
- [ ] **EVNT-02**: Event duration is configurable — from 1 hour to several weeks
- [ ] **EVNT-03**: Events with no prize field set are treated as test/internal events (no public winner announcement)
- [ ] **EVNT-04**: Only one event can be active at a time in v1
- [ ] **EVNT-05**: Scoring cutoff is enforced server-side — runs submitted after cutoff are rejected
- [ ] **EVNT-06**: HUD displays the correct event name, prize, and countdown for the active event
- [ ] **EVNT-07**: After event ends, a "scoring closed" state is shown to players

### Gameplay

- [ ] **GAME-01**: Players get exactly 5 attempts per day per active event (existing — enforced by DB trigger)
- [ ] **GAME-02**: Each day uses a seeded RNG so all players face the same challenge on the same day (existing)
- [ ] **GAME-03**: Score is saved to Supabase after each run with event reference (existing — needs event linkage)
- [ ] **GAME-04**: Attempt dots in HUD reflect remaining daily attempts in real time
- [ ] **GAME-05**: Game Over screen shows run score, best score, remaining attempts, current leaderboard rank
- [ ] **GAME-06**: Fish Stack (Game 02) is playable with full Supabase event integration

### Leaderboard

- [ ] **LBRD-01**: Live leaderboard shows top scores for the active event, refreshed on panel open
- [ ] **LBRD-02**: Player's own rank is shown in HUD at all times during active event
- [ ] **LBRD-03**: Leaderboard distinguishes 18+ competitors from under-18 practice players (separate views)
- [ ] **LBRD-04**: At event cutoff, leaderboard freezes; winner (#1 on 18+ board) is surfaced in admin

### Admin

- [ ] **ADMN-01**: Admin panel requires `is_admin = true` on profile to access (existing — needs hardening)
- [ ] **ADMN-02**: Admin can create, edit, and delete events
- [ ] **ADMN-03**: Admin can manually trigger "new event live" (post-show publish flow)
- [x] **ADMN-04**: Admin can view the frozen leaderboard after event ends (Competition events → **Past**, select event) with **Winner** banner for rank #1; active/upcoming tabs for full lifecycle. (18+–only winner line remains tied to **LBRD-03** if you split boards.)
- [ ] **ADMN-05**: Admin can mark a player as banned (sets `is_banned`; banned players cannot submit scores)
- [ ] **ADMN-06**: Admin dashboard shows active event status, player count, top 3 scores at a glance
- [x] **ADMN-07**: Admin can sign out from the admin panel (ends Supabase session; returns to sign-in gate)

### Social & Sharing

- [ ] **SOCL-01**: After each run, player can share a score card (PNG or native share sheet) with score, rank, game name
- [ ] **SOCL-02**: Shared link opens the game directly (one link, no app install, no redirect friction)
- [ ] **SOCL-03**: OG meta tags on the page (title, description, image) so social previews look good when shared

### Anti-cheat & Security

- [ ] **SECU-01**: Score submissions require valid Supabase auth JWT (existing via RLS — already enforced)
- [ ] **SECU-02**: Score submission includes a server-side-checkable gameplay hash (input count, duration, seed match) to detect trivially fake scores
- [x] **SECU-03**: Supabase JS is pinned to a specific CDN version (no floating "latest")
- [ ] **SECU-04**: `is_banned` flag is checked on score submission; banned players' runs are rejected

## v2 Requirements

### Multiple Events

- **MEVT-01**: Multiple events can run simultaneously (e.g., main public event + corporate client event)
- **MEVT-02**: Players can choose which event to enter at game start
- **MEVT-03**: Each event has its own leaderboard, attempt count, and prize

### Prize Claiming

- **PRIZ-01**: Winner receives automated email notification after event ends
- **PRIZ-02**: Winner completes an in-app claim form (name, address, age verification document)
- **PRIZ-03**: Admin receives claim submission notification

### Geo / Legal

- **LEGL-01**: Players in excluded jurisdictions see a "not available in your region" gate
- **LEGL-02**: Full sweepstakes disclosure / official rules page linked from HUD
- **LEGL-03**: Age verification beyond checkbox (ID verification integration)

### Notifications

- **NOTF-01**: Player receives email when a new event goes live
- **NOTF-02**: Player receives email reminder when scoring closes in 24 hours
- **NOTF-03**: Player receives push notification (PWA) for same triggers

### Additional Games

- **GAME-07**: Game 03 with full event integration
- **GAME-08**: Games 04–10 per GAME_BIBLE roadmap

## Out of Scope

| Feature | Reason |
|---------|--------|
| Payment / purchase flows | Free to play always; no monetization in product, ever |
| Native mobile app | Web-first; PWA covers install; native adds cost/complexity |
| Merch store | IP established now, commerce is a separate future product |
| OAuth / social login | Email sufficient for v1; adds complexity without clear value |
| Full legal compliance implementation | Framework built v1; actual legal review before public launch |
| Video replay of winning run (in-app) | Show does this live; in-app replay is v2+ |
| Real-time WebSocket leaderboard | Polling on panel open is sufficient for v1 volume |

## Traceability

| Requirement | Phase | Status |
|-------------|-------|--------|
| SHEL-01 – SHEL-05 | Phase 1 | Pending |
| AUTH-01 – AUTH-06 | Phase 2 | Pending |
| EVNT-01 – EVNT-07 | Phase 3 | Pending |
| GAME-01 – GAME-05 | Phase 4 | Pending |
| GAME-06 | Phase 5 | Pending |
| LBRD-01 – LBRD-04 | Phase 4 | Pending |
| ADMN-01 – ADMN-06 | Phase 3 | Pending |
| SOCL-01 – SOCL-03 | Phase 6 | Pending |
| SECU-01 – SECU-04 | Phase 4 | Pending |

**Coverage:**
- v1 requirements: 34 total
- Mapped to phases: 34
- Unmapped: 0 ✓

---
*Requirements defined: 2026-04-02*
*Last updated: 2026-04-02 after initial definition*
