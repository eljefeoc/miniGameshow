---
phase: 01-phone-first-shell-pwa
plan: 02
subsystem: game-shell
tags: [pwa, home-shell, portrait, vercel, routing, mobile]
dependency_graph:
  requires: []
  provides: [home-shell-index, vercel-route-slash-index]
  affects: [prototypes/index.html, vercel.json]
tech_stack:
  added: []
  patterns: [env(safe-area-inset-top/bottom), 100dvh min-height, clamp() font sizing, viewport-fit=cover]
key_files:
  created:
    - prototypes/index.html
  modified:
    - vercel.json
decisions:
  - "Play button uses anchor tag with href=/penguin-game.html — no JS navigation needed; JS handler is stub for future event param passing"
  - "Event card is a static placeholder — Phase 3 wires real event data from Supabase"
  - "Character art is emoji placeholder — Plan 03 replaces with cropped pengu-sheet.png icon"
metrics:
  duration: 71s
  completed: 2026-04-02T17:13:20Z
  tasks_completed: 2
  files_modified: 2
---

# Phase 01 Plan 02: Portrait Home Shell Summary

Portrait-first home shell at `prototypes/index.html` serving as the app entry point at `/`, with `vercel.json` updated to route `/` to it instead of directly to the game.

## Objective

Create a discovery-moment landing page that a player sees when they tap a shared link. Portrait-first, bold, event info front and center. Tapping Play navigates to the game.

## Tasks Completed

### Task 1: Create prototypes/index.html — portrait home shell

Created new plain HTML file at `prototypes/index.html` with no build step. Key design decisions:

- **Layout:** Flexbox column, `min-height: 100dvh`, vertically scrollable, portrait-first
- **Safe-area insets:** `max(48px, env(safe-area-inset-top))` top padding, `max(32px, env(safe-area-inset-bottom))` bottom padding — protects against iOS notch and Android gesture bar
- **Play button:** `<a>` tag with `href="/penguin-game.html"`, `min-height: 64px` (well above 44px minimum), teal background, press-down animation on `:active`
- **Colors:** Uses only existing CSS custom properties (`--teal`, `--yellow`, `--brown`, `--cream`, `--dark`) — no new colors introduced
- **Fonts:** Same Google Fonts link as `penguin-game.html` (Titan One + Bubblegum Sans) with preconnect hints
- **No horizontal scroll:** `overflow-x: hidden` on `html, body`
- **No external JS:** Single inline `<script>` block with only a click handler stub for future enhancement
- **PWA:** `<link rel="manifest" href="/manifest.json">` included (manifest created in Plan 03)
- **Event card:** Static placeholder — Phase 3 wires real Supabase data

**Commit:** 17fb084

### Task 2: Update vercel.json to route / to index.html

Single targeted edit: changed the rewrite destination from `/penguin-game.html` to `/index.html`. All other fields (`$schema`, `buildCommand`, `outputDirectory`) unchanged. The game remains directly accessible at `/penguin-game.html` as a static file — no additional rewrite needed.

**Commit:** 8f8cd46

## Verification Results

| Check | Result |
|-------|--------|
| `viewport-fit=cover` in index.html | 1 match (confirmed) |
| `penguin-game.html` href in index.html | 5 matches (href + comments) |
| `min-height: 64px` in index.html | 1 match (confirmed) |
| `safe-area-inset-top/bottom` in index.html | 2 occurrences (confirmed) |
| `overflow-x: hidden` in index.html | 1 match (confirmed) |
| No `<script src=` in index.html | 0 matches (no external JS — confirmed) |
| `<!DOCTYPE html>` in index.html | 1 match (confirmed) |
| `destination` in vercel.json | `/index.html` (correct) |
| `penguin-game.html` in vercel.json | 0 matches (old route removed) |
| vercel.json is valid JSON | Confirmed via python3 |

## Decisions Made

1. **Anchor tag for Play button:** Used `<a href="/penguin-game.html">` rather than a `<button>` with JS navigation. The anchor provides native browser back/forward support and correct semantics. The JS `click` handler is a stub for future enhancement (passing event parameters).

2. **Event card as static placeholder:** The event card shows hardcoded "Pengu Fisher" and "Play now — prizes coming soon". Phase 3 wires this to real Supabase event data. This is intentional — Plan 02 scope is shell/routing only.

3. **Emoji character art:** The penguin emoji (`🐧`) is a placeholder for the character art. Plan 03 replaces this with a cropped PNG from `prototypes/assets/pengu-sheet.png`.

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| `event-name` (hardcoded "Pengu Fisher") | prototypes/index.html:147 | Phase 3 wires real Supabase event data |
| `event-prize` (hardcoded "prizes coming soon") | prototypes/index.html:148 | Phase 3 wires real event prize field |
| Character art emoji `🐧` | prototypes/index.html:143 | Plan 03 replaces with cropped pengu-sheet.png icon |

These stubs do not prevent the plan's goal (shell/routing) from being achieved. The Play button works correctly. The event card is intentionally placeholder per plan scope.

## Self-Check: PASSED

Files exist:
- FOUND: prototypes/index.html (created)
- FOUND: vercel.json (modified)

Commits exist:
- FOUND: 17fb084 (index.html task)
- FOUND: 8f8cd46 (vercel.json task)
