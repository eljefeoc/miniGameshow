---
phase: 02-auth-player-profiles
plan: 03
subsystem: auth
tags: [vanilla-js, supabase, age-gate, practice-mode, play-mode-state-machine]

# Dependency graph
requires:
  - phase: 02-01
    provides: playerIs18Plus module variable set from profiles.is_18_plus after sign-in
provides:
  - practice playMode path for under-18 signed-in users
  - amber Practice Mode indicator UI in first-play card
  - four-value playMode state machine: guest | competing | practice | freeplay
  - score submission for practice mode (same as competing)
affects:
  - 02-auth-player-profiles (leaderboard separation deferred to Phase 4)
  - Phase 4 leaderboard work (will separate by is_18_plus flag)

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "playMode state machine branches on playerIs18Plus before setting competing vs practice"
    - "fp-practice-notice element hidden by default, shown/hidden by refreshTitleFirstPlayCard and onSignedOut"
    - "practice mode submits scores to Supabase same as competing (submitRunToSupabase triggered for both)"

key-files:
  created: []
  modified:
    - prototypes/penguin-game.html

key-decisions:
  - "practice mode submits scores to Supabase — scores save but leaderboard separation is a Phase 4 concern (is_18_plus flag already on profile)"
  - "practice mode uses dailySeed same as competing — same daily challenge, only visual indicator and future leaderboard differ"
  - "onSignedOut resets playerIs18Plus to false — prevents stale state if user switches accounts"

patterns-established:
  - "playMode state machine: guest -> (sign in) -> competing (18+) or practice (<18) -> (5 attempts) -> freeplay"

requirements-completed: [AUTH-06]

# Metrics
duration: 2min
completed: 2026-04-03
---

# Phase 02 Plan 03: Practice Mode State Machine Summary

**Under-18 users routed to playMode='practice' with amber indicator via playerIs18Plus flag; scores still save to Supabase; 18+ competing path unchanged**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-03T18:36:05Z
- **Completed:** 2026-04-03T18:38:00Z
- **Tasks:** 1/2 (Task 2 is checkpoint:human-verify — paused for human verification)
- **Files modified:** 1

## Accomplishments
- `fetchAttemptsAndSetMode` now branches on `playerIs18Plus`: under-18 signed-in users get `playMode='practice'`, 18+ users get `playMode='competing'`
- Added `#fp-practice-notice` amber-bordered div in first-play card HTML (hidden by default, shown when `playMode === 'practice'`)
- `submitRunToSupabase` triggered for both `competing` and `practice` modes — scores save to Supabase for under-18 users
- `onSignedOut` resets `playerIs18Plus = false` and hides practice notice
- Practice gameover overlay shows "Practice mode" tip text with correct attempt messaging

## Task Commits

Each task was committed atomically:

1. **Task 1: Add 'practice' playMode path and Practice Mode indicator** - `11fd772` (feat)

**Plan metadata:** pending final commit after human verification

## Files Created/Modified
- `prototypes/penguin-game.html` - fetchAttemptsAndSetMode practice branch, #fp-practice-notice HTML, showModeOverlay practice gameover case, submitRunToSupabase practice trigger, onSignedOut cleanup

## Decisions Made
- Practice mode scores ARE submitted to Supabase (same path as competing) — the leaderboard separation based on `is_18_plus` profile flag is deferred to Phase 4. This avoids partial implementation; the data is correct, display separation comes later.
- Practice mode uses `dailySeed` (same daily challenge as 18+ competitors) — under-18 players experience the same course, just without prize eligibility.
- `playerIs18Plus` reset to `false` on sign-out to prevent stale state if a different user signs in on the same device.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 03 Task 1 complete; awaiting human verification of the full auth flow (signup, session persistence, account tab, practice mode indicator)
- After human approval, plan is complete and Phase 02 is done
- Phase 3 (Event System) can proceed after verification passes

---
*Phase: 02-auth-player-profiles*
*Completed: 2026-04-03 (pending human verification)*
