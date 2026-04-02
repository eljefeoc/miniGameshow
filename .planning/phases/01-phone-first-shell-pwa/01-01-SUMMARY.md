---
phase: 01-phone-first-shell-pwa
plan: 01
subsystem: game-shell
tags: [responsive, hud, viewport, controls, pwa, mobile]
dependency_graph:
  requires: []
  provides: [hud-responsive-collapse, viewport-fit, fixed-controls, play-gated-nudge]
  affects: [prototypes/penguin-game.html, prototypes/hud.css]
tech_stack:
  added: []
  patterns: [position:fixed for viewport-anchored controls, env(safe-area-inset-bottom), CSS :not() selector for structural targeting, _playStarted guard flag]
key_files:
  created: []
  modified:
    - prototypes/hud.css
    - prototypes/penguin-game.html
decisions:
  - "Used .ghud-stat:not(.ghud-stat-rank):not(.ghud-stat-last) to target score stat without modifying hud.js"
  - "Set _playStarted flag in startFromOverlay() — the single code path that transitions state to 'playing'"
  - "Changed #controls to position:fixed so buttons anchor to viewport bottom regardless of canvas scale"
metrics:
  duration: 80s
  completed: 2026-04-02T17:08:57Z
  tasks_completed: 2
  files_modified: 2
---

# Phase 01 Plan 01: Phone-First Shell Layout Summary

HUD responsive collapse and game viewport hardening for 375px phone playability — `viewport-fit=cover`, fixed controls, gated rotate nudge, and HUD collapse to dots+menu on narrow screens.

## Objective

Fix the game viewport, canvas sizing, and HUD so Pengu Fisher is fully playable on a 375px-wide phone screen without horizontal scroll, with a correctly collapsed HUD on narrow screens.

## Tasks Completed

### Task 1: Harden HUD responsive collapse in hud.css

Extended the existing `@media (max-width: 480px)` block in `prototypes/hud.css` to implement the full D-07/D-08 collapse:

- `.ghud-prize { display: none; }` — hides show title and schedule/countdown line
- `.ghud-avatar { display: none; }` — hides avatar (accessible via menu)
- `.ghud-stat:not(.ghud-stat-rank):not(.ghud-stat-last) { display: none; }` — hides score stat cell using structural selector (avoids modifying hud.js)
- `--ghud-h: 56px` and `min-height: 56px` preserved — HUD height contract unchanged (D-09)

**Commit:** 5b8ed34

### Task 2: Fix viewport meta, controls anchor, and rotate-nudge timing in penguin-game.html

Four targeted edits to `prototypes/penguin-game.html`:

- **Edit A:** Added `viewport-fit=cover` to viewport meta for notched iPhone safe-area support
- **Edit B:** Changed `#controls` from `position:absolute` to `position:fixed` so buttons anchor to viewport bottom regardless of canvas scale (D-10); kept `env(safe-area-inset-bottom)` padding (D-12)
- **Edit C:** Added `min-width: 80px; min-height: 60px` to `.thumb-btn` as belt-and-suspenders for D-11 tap target minimum
- **Edit D:** Added `let _playStarted = false` flag; updated nudge condition to `(_playStarted && vw < 480 && vh > vw * 1.3)`; set `_playStarted = true` in `startFromOverlay()` at the `state='playing'` transition point (D-05)

**Commit:** 25d5d2c

## Verification Results

| Check | Result |
|-------|--------|
| `hud.css` display:none count | 4 (increased by 3) |
| `#controls` uses position:fixed | Confirmed |
| `viewport-fit=cover` present once | Confirmed |
| `_playStarted` occurrences | 3 (declaration + guard + assignment) |
| `--ghud-h: 56px` unchanged | Confirmed |
| `min-height: 56px` unchanged | Confirmed |

## Decisions Made

1. **Structural CSS selector for score stat:** Used `.ghud-stat:not(.ghud-stat-rank):not(.ghud-stat-last)` to target the score stat cell without modifying `hud.js`. This is fragile if new `.ghud-stat` elements are added to hud.js, but the correct approach until a dedicated class is added to hud.js in a future plan.

2. **Single play-start path:** `_playStarted = true` set only in `startFromOverlay()` — this is the single code path that transitions game state to `'playing'`, confirmed by grep. No other code paths set `state='playing'`.

3. **Controls z-index:** Kept existing `z-index: 10` on `#controls` — no change needed as there's no z-index conflict at this level.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — no placeholder data or unconnected UI introduced in this plan.

## Self-Check: PASSED

Files exist:
- FOUND: prototypes/hud.css (modified)
- FOUND: prototypes/penguin-game.html (modified)

Commits exist:
- FOUND: 5b8ed34 (hud.css task)
- FOUND: 25d5d2c (penguin-game.html task)
