---
phase: 01-phone-first-shell-pwa
verified: 2026-04-02T20:00:00Z
status: human_needed
score: 9/11 must-haves verified
re_verification: false
gaps: []
human_verification:
  - test: "PWA installability — Add to Home Screen prompt"
    expected: "Chrome on Android shows 'Add to Home Screen' option in three-dot menu; DevTools Application > Manifest shows no installability errors"
    why_human: "Browser install prompt requires a running HTTPS server; cannot verify with static file grep"
  - test: "SHEL-03 — 3-second interactive load on LTE"
    expected: "DOMContentLoaded under 3 seconds with DevTools Network throttled to Fast 3G / Slow 4G"
    why_human: "Load time depends on network, CDN caching, and runtime behavior — not statically verifiable; the 129KB HTML + 299KB sprite + Supabase ESM bundle make this borderline and worth confirming"
  - test: "HUD menu touch target size — SHEL-02 gap assessment"
    expected: "Confirm whether the 30×30px ghud-menu button is acceptable given the 56px HUD height context, or flag for follow-up fix"
    why_human: "The ghud-menu and ghud-avatar elements measure 30×30px in CSS — below the 44×44px SHEL-02 minimum. The game controls (.thumb-btn 80×60px) and Play button (64px min-height) are compliant. A human needs to decide whether the HUD hamburger menu is in-scope for Phase 1 or a pre-existing element deferred to Phase 2."
---

# Phase 01: Phone-First Shell PWA Verification Report

**Phase Goal:** The game is fully playable on a real phone — full-viewport, touch-optimized, no horizontal scroll — and installable from the browser without requiring an app store.
**Verified:** 2026-04-02T20:00:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Game renders without horizontal scrolling on 375px phone screen | VERIFIED | `overflow-x:hidden` on html/body in penguin-game.html; `overflow:hidden` on html/body; viewport meta `width=device-width, initial-scale=1.0` |
| 2 | Portrait orientation shows rotate nudge after Play is tapped; layout does not break | VERIFIED | `_playStarted` flag (3 occurrences confirmed) guards nudge in `resizeCanvas()`; `startFromOverlay()` sets `_playStarted = true` |
| 3 | Canvas fills available viewport below HUD with no blank bars | VERIFIED | `resizeCanvas()` subtracts `window.GameshowHud.height()` from `innerHeight`; `#controls` uses `position:fixed` so canvas area is unobstructed |
| 4 | HUD collapses to attempt dots, countdown, and menu icon only at ≤ 480px | VERIFIED | `@media (max-width: 480px)` in hud.css hides `.ghud-prize`, `.ghud-avatar`, `.ghud-stat-rank`, and score stat cell via structural selector |
| 5 | HUD height stays fixed at 56px; resizeCanvas() unaffected | VERIFIED | `--ghud-h: 56px` and `min-height: 56px` unchanged; confirmed by grep |
| 6 | Visiting `/` on Vercel loads portrait home shell, not penguin-game.html | VERIFIED | `vercel.json` rewrites `"source": "/"` to `"destination": "/index.html"` |
| 7 | Home shell is portrait-first: vertically scrollable, shows event placeholder and Play button | VERIFIED | `overflow-x: hidden`, `min-height: 100dvh`, flexbox column layout, `.btn-play` with `href="/penguin-game.html"` confirmed in index.html |
| 8 | App is PWA-installable (manifest linked, icons exist, standalone display) | VERIFIED (automated) | `manifest.json` valid JSON; `miniGameshow` name, `#2A1A0E` theme/background, `standalone` display, `orientation: "any"`; icon-192.png (516 bytes, valid PNG 192×192) and icon-512.png (2360 bytes) exist; manifest linked from both HTML files |
| 9 | Supabase JS CDN is pinned to a specific version (SECU-03) | VERIFIED | `@supabase/supabase-js@2.101.1` pinned in penguin-game.html; no floating `@2/+esm` reference remains |
| 10 | PWA Add to Home Screen prompt appears on real device | UNCERTAIN | Requires live HTTPS browser test — cannot verify statically |
| 11 | Game loads and is interactive within 3 seconds on LTE (SHEL-03) | UNCERTAIN | 129KB HTML + 299KB sprite PNG + Supabase ESM bundle is borderline; font preloads added; human DevTools verification required |

**Score:** 9/11 truths verified (2 require human confirmation)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `prototypes/penguin-game.html` | Game shell with viewport meta, HUD-height-aware canvas, fixed controls | VERIFIED | viewport-fit=cover, position:fixed #controls, _playStarted guard, min-width/min-height on .thumb-btn, GameshowHud.height() present |
| `prototypes/hud.css` | HUD responsive collapse rules | VERIFIED | @media (max-width:480px) hides .ghud-prize, .ghud-avatar, .ghud-stat-rank, score stat; --ghud-h: 56px unchanged |
| `prototypes/index.html` | Portrait home shell — entry point | VERIFIED | viewport-fit=cover, btn-play href, safe-area insets, overflow-x:hidden, min-height:64px Play button, manifest link |
| `vercel.json` | Route rewrite / → index.html | VERIFIED | `"destination": "/index.html"` confirmed; `/penguin-game.html` removed from rewrites |
| `prototypes/manifest.json` | PWA web app manifest | VERIFIED | Valid JSON; name "miniGameshow", theme_color "#2A1A0E", background_color "#2A1A0E", display "standalone", orientation "any", two icon entries |
| `prototypes/assets/icon-192.png` | PWA icon 192×192 | VERIFIED | Exists, 516 bytes, valid PNG 192×192 8-bit RGB |
| `prototypes/assets/icon-512.png` | PWA icon 512×512 | VERIFIED | Exists, 2360 bytes (placeholder art — dark brown + teal square) |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| prototypes/hud.css | #gameshow-hud | @media (max-width:480px) hiding .ghud-prize, .ghud-avatar | WIRED | Lines 189-199: full media block with all required rules |
| prototypes/penguin-game.html | resizeCanvas() | window.GameshowHud.height() subtracted from innerHeight | WIRED | Line 1169: `const hudH = window.GameshowHud.height ? window.GameshowHud.height() : 56;` |
| prototypes/index.html | /penguin-game.html | Play button href | WIRED | Line 162: `<a href="/penguin-game.html" class="btn-play">` |
| vercel.json | prototypes/index.html | rewrites destination | WIRED | `"destination": "/index.html"` confirmed |
| prototypes/index.html | prototypes/manifest.json | `<link rel="manifest">` | WIRED | Line 10: `<link rel="manifest" href="/manifest.json">` |
| prototypes/penguin-game.html | prototypes/manifest.json | `<link rel="manifest">` | WIRED | Line 8: `<link rel="manifest" href="/manifest.json">` |
| prototypes/penguin-game.html | Supabase JS (pinned) | dynamic import @2.101.1 | WIRED | Line 2646: `import('https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.101.1/+esm')` |

### Data-Flow Trace (Level 4)

Not applicable — this phase produces layout, configuration, and asset artifacts. No dynamic data rendering was introduced. Event card in index.html is an intentional static placeholder (Phase 3 scope).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| vercel.json routes / to index.html | `grep "destination" vercel.json` | `/index.html` | PASS |
| manifest.json is valid JSON | `python3 -c "import json; json.load(...)"` | `valid JSON` | PASS |
| manifest.json has required fields | grep for miniGameshow, #2A1A0E, standalone | All 3 found | PASS |
| icon PNGs are valid | `file icon-192.png` | PNG 192x192, 8-bit/color RGB | PASS |
| Supabase version pinned (not floating) | `grep "supabase-js@2/"` | 0 matches | PASS |
| _playStarted guard present | `grep -c "_playStarted"` | 3 occurrences | PASS |
| PWA Add to Home Screen | Requires live browser | N/A | SKIP — human needed |
| LTE 3-second load | Requires DevTools throttle | N/A | SKIP — human needed |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| SHEL-01 | 01-01 | Game fully playable on 375px phone, no horizontal scroll | SATISFIED | viewport meta, overflow:hidden, canvas fills viewport, resizeCanvas() uses HUD height |
| SHEL-02 | 01-02 | All touch targets ≥ 44×44px; tap-to-play works on iOS/Android | PARTIAL | .thumb-btn (80×60px min) and .btn-play (64px min-height) are compliant; ghud-menu and ghud-avatar are 30×30px — below spec; SHEL-02 says "all touch targets" |
| SHEL-03 | 01-03 | Interactive within 3 seconds on LTE | NEEDS HUMAN | Font preloads added, Supabase pinned to ESM; file sizes (129KB HTML, 299KB sprite, ~300KB+ Supabase ESM) make this borderline; DevTools verification required |
| SHEL-04 | 01-03 | PWA manifest with icon and theme color | SATISFIED | manifest.json valid with name, theme_color, display standalone; icons exist; manifest linked from both HTML files |
| SHEL-05 | 01-01, 01-02 | Landscape and portrait work on phone without breaking | SATISFIED | _playStarted guards rotate nudge (game), overflow-x:hidden + min-height:100dvh handles orientation in home shell; resizeCanvas() handles both orientations |
| SECU-03 | 01-03 | Supabase JS pinned to specific CDN version | SATISFIED | @2.101.1 pinned, floating @2/+esm removed |

**Note on SECU-03 traceability:** REQUIREMENTS.md Traceability table lists SECU-01–SECU-04 under Phase 4, but SECU-03 is satisfied and claimed by Plan 01-03. This is a documentation discrepancy in REQUIREMENTS.md — the work was done in Phase 1 and the requirement is [x] marked complete.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| prototypes/index.html | 159 | `"Play now — prizes coming soon"` hardcoded in event-prize | Info | Intentional Phase 3 stub — event card data wired in Phase 3 per plan spec; does not block Phase 1 goal |
| prototypes/index.html | 152 | Emoji `🐧` as character art placeholder | Info | Intentional Plan 03 stub — Plan 03 summary documents this; icon art replacement deferred |
| prototypes/assets/icon-192.png | — | Placeholder art (dark brown + teal square) | Info | Functional PNG, valid for PWA installability; not final penguin art; ImageMagick unavailable during execution |
| prototypes/assets/icon-512.png | — | Same placeholder art at 512×512 | Info | Same as above |
| prototypes/hud.css | 128-168 | ghud-menu and ghud-avatar at 30×30px | Warning | Below SHEL-02 44×44px minimum; pre-existing in hud.js/hud.css; Phase 1 plans addressed .thumb-btn and .btn-play but not HUD interactive elements |

### Human Verification Required

#### 1. PWA Installability — Add to Home Screen

**Test:** Deploy to Vercel (or serve via HTTPS locally). Open Chrome on Android. Navigate to the root URL. Tap the three-dot menu.
**Expected:** "Add to Home Screen" option appears; DevTools Application > Manifest shows manifest detected, name "miniGameshow", theme color "#2A1A0E", icons listed, and no blocking installability errors.
**Why human:** Browser install prompts require HTTPS and active browser session — cannot verify from filesystem grep alone.

#### 2. SHEL-03 — 3-Second Interactive Load on LTE

**Test:** Open DevTools > Network > throttle to "Fast 3G" or "Slow 4G". Hard-reload `/penguin-game.html`. Check DOMContentLoaded time in Network summary.
**Expected:** DOMContentLoaded under 3 seconds. If over, note blocking resources (likely sprite PNG or Supabase ESM). Do not block Phase 1 sign-off if marginally over — flag for Phase 4 optimization.
**Why human:** Load time depends on CDN caching, network conditions, and JavaScript parse time — not statically verifiable. File sizes (129KB HTML + 299KB sprite + ~300KB Supabase ESM uncompressed) make this worth confirming.

#### 3. HUD Menu Touch Target — SHEL-02 Scope Decision

**Test:** Inspect the hamburger menu button (`.ghud-menu`) in mobile DevTools. Measure effective tap area.
**Expected:** Confirm whether the 30×30px visual element meets tap target requirements in context (e.g., the 56px HUD row gives more hit area than the visual box implies), or flag as a gap needing a Phase 2 fix (add `padding` to extend hit area to 44×44px without changing visual size).
**Why human:** The CSS measures 30×30px which is below spec, but the effective interaction area within the 56px HUD bar may be larger. A human UX check on a real device is needed to determine if this is a real usability issue.

### Gaps Summary

No hard blockers found. All artifacts exist, are substantive, and are correctly wired. The two automated "UNCERTAIN" items (PWA prompt, LTE load time) and the SHEL-02 HUD touch target question require human confirmation before the phase can be fully signed off.

The placeholder icons and event card stubs are intentional and in-scope — they do not block Phase 1 goal achievement (installable shell, not final art).

---

_Verified: 2026-04-02T20:00:00Z_
_Verifier: Claude (gsd-verifier)_
