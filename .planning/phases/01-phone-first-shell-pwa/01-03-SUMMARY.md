---
phase: 01-phone-first-shell-pwa
plan: 03
subsystem: ui
tags: [pwa, manifest, icons, cdn, fonts, supabase, security]

# Dependency graph
requires:
  - phase: 01-phone-first-shell-pwa
    provides: index.html home shell and penguin-game.html with responsive controls

provides:
  - PWA manifest.json with miniGameshow name, dark theme, standalone display
  - 192x192 and 512x512 icon PNG files (placeholder art, dark brown + teal)
  - Manifest link tag in both index.html and penguin-game.html
  - apple-touch-icon in both HTML files
  - Font preload tags for Titan One and Bubblegum Sans (as=font, crossorigin)
  - Supabase JS CDN pinned to immutable @2.101.1 version URL

affects: [02-auth-player-profiles, 04-gameplay-polish-security]

# Tech tracking
tech-stack:
  added: [PWA manifest, woff2 font preloads]
  patterns: [immutable CDN versioning for supply-chain safety, font preloads for FOUT prevention]

key-files:
  created:
    - prototypes/manifest.json
    - prototypes/assets/icon-192.png
    - prototypes/assets/icon-512.png
  modified:
    - prototypes/index.html
    - prototypes/penguin-game.html

key-decisions:
  - "Placeholder icons (dark brown bg + teal square) used since ImageMagick and PIL unavailable; manifest still valid for PWA installability"
  - "Supabase JS pinned to @2.101.1 via dynamic import URL — SRI hash on dynamic import() not supported by browsers, immutable URL achieves same security goal"
  - "Font preload URLs verified against live Google Fonts API response (v22 Bubblegum Sans, v17 Titan One latin subsets)"

patterns-established:
  - "CDN dependencies pinned to exact version with comment explaining security rationale (SECU-03 pattern)"
  - "Font preloads placed before stylesheet link with as=font and crossorigin attributes"

requirements-completed:
  - SHEL-03
  - SHEL-04
  - SECU-03

# Metrics
duration: 5min
completed: 2026-04-02
---

# Phase 01 Plan 03: PWA Manifest & CDN Security Summary

**PWA manifest with miniGameshow branding, icon PNGs, font preloads eliminating FOUT, and Supabase JS pinned to immutable @2.101.1 CDN URL**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-04-02T17:14:00Z
- **Completed:** 2026-04-02T17:17:10Z
- **Tasks:** 2 (+ 1 checkpoint auto-approved)
- **Files modified:** 5

## Accomplishments

- Created manifest.json with locked values (name, theme_color, display, orientation, icons) per decisions D-13 through D-16
- Generated valid 192x192 and 512x512 PNG placeholder icons using pure Python stdlib (zlib/struct) since ImageMagick and PIL were not available
- Linked manifest in both index.html and penguin-game.html; added apple-touch-icon to both
- Added font preload tags using verified current woff2 URLs from Google Fonts API (latin subsets)
- Pinned Supabase JS dynamic import from floating @2 to exact @2.101.1, eliminating CDN supply-chain risk per SECU-03

## Task Commits

Each task was committed atomically:

1. **Task 1: Create manifest.json and generate PWA icons** - `88bd193` (feat)
2. **Task 2: Link manifest, pin Supabase CDN, and font preloads** - `d365ed9` (feat)

## Files Created/Modified

- `prototypes/manifest.json` - PWA web app manifest with miniGameshow branding
- `prototypes/assets/icon-192.png` - 192x192 placeholder icon PNG (dark brown bg, teal center square)
- `prototypes/assets/icon-512.png` - 512x512 placeholder icon PNG (dark brown bg, teal center square)
- `prototypes/index.html` - Added apple-touch-icon link tag
- `prototypes/penguin-game.html` - Added manifest link, apple-touch-icon, font preloads, pinned Supabase CDN

## Decisions Made

- ImageMagick unavailable and PIL not installed on this machine; used pure Python stdlib (struct + zlib) to generate valid placeholder PNGs. Icons are functional for PWA installability — the "happy pose" crop from pengu-sheet.png is deferred until tooling is available.
- SRI integrity hash on dynamic `import()` is a browser spec limitation (not yet supported). Used immutable CDN URL (`@2.101.1`) instead — a pinned URL on jsDelivr is content-immutable, achieving the same supply-chain security goal.
- Font preload URLs fetched from live Google Fonts API to ensure current versions (v22 for Bubblegum Sans, v17 for Titan One). The plan's example URLs were stale (v13/v18).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Font preload URLs updated to current versions**
- **Found during:** Task 2 (font preloads)
- **Issue:** Plan's example woff2 URLs (v13 Titan One, v18 Bubblegum Sans) were stale; live API returns v17 and v22
- **Fix:** Fetched `https://fonts.googleapis.com/css2?family=Titan+One&family=Bubblegum+Sans&display=swap` and extracted current latin subset URLs
- **Files modified:** prototypes/penguin-game.html
- **Verification:** curl confirmed URLs match current Google Fonts CSS response
- **Committed in:** d365ed9 (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (1 bug — stale font URLs)
**Impact on plan:** Required to ensure preload links actually resolve. No scope creep.

## Issues Encountered

- ImageMagick not installed on this machine; PIL also unavailable. Used fallback approach (pure Python struct/zlib PNG generation) to create valid placeholder icons. The manifest is fully functional for PWA installability with placeholder art.

## User Setup Required

**Icon art:** The placeholder icons (dark brown + teal square) are functional but not final. To replace with the "happy pose" crop from `prototypes/assets/pengu-sheet.png`, run:
```bash
# With ImageMagick (when available):
convert prototypes/assets/pengu-sheet.png -gravity NorthWest -crop 192x192+0+0 +repage -resize 192x192 prototypes/assets/icon-192.png
convert prototypes/assets/pengu-sheet.png -gravity NorthWest -crop 192x192+0+0 +repage -resize 512x512 prototypes/assets/icon-512.png
```
Or crop manually in any image editor. The PWA manifest works with either the placeholder or final icons.

## Known Stubs

- `prototypes/assets/icon-192.png` — Placeholder art (dark brown bg + teal square). Functional PNG meeting PWA requirements but not final penguin character art. Replacement requires ImageMagick or manual crop from pengu-sheet.png. Does not block PWA installability.
- `prototypes/assets/icon-512.png` — Same as above at 512x512.

## Next Phase Readiness

- Site is PWA-installable: manifest.json links from both HTML files, icons exist, standalone display configured
- Supabase CDN is version-pinned (SECU-03 resolved)
- Font preloads eliminate FOUT on first load
- Phase 02 (Auth & Player Profiles) can proceed — no blockers from this plan

## Self-Check: PASSED

All required files exist:
- FOUND: prototypes/manifest.json
- FOUND: prototypes/assets/icon-192.png
- FOUND: prototypes/assets/icon-512.png

All commits exist:
- FOUND: 88bd193 (Task 1)
- FOUND: d365ed9 (Task 2)

---
*Phase: 01-phone-first-shell-pwa*
*Completed: 2026-04-02*
