# Phase 1: Phone-First Shell & PWA - Context

**Gathered:** 2026-04-02
**Status:** Ready for planning

<domain>
## Phase Boundary

Make the existing Pengu Fisher game fully playable on phones by: (1) creating a portrait-oriented gameshow home page as a separate entry screen, (2) fixing viewport/canvas layout and touch controls for the landscape game, (3) adding a PWA manifest so the site is installable, and (4) collapsing the HUD for narrow screens.

This phase does NOT include: event system wiring, auth changes, new games, or leaderboard changes.
</domain>

<decisions>
## Implementation Decisions

### Architecture: Gameshow Home Page

- **D-01:** A **separate portrait-oriented home/shell page** is created (e.g., `index.html` or a new route) that is the entry point of the app — this is distinct from the current welcome overlay inside `penguin-game.html`.
- **D-02:** The home page is **portrait-first** — vertically scrollable, designed for a phone held upright. It shows event info, prize, and a Play button.
- **D-03:** Tapping "Play" on the home page launches the game. The existing Vercel route for `/` should point to this new home shell, not directly to `penguin-game.html`.

### Orientation Strategy

- **D-04:** Pengu Fisher remains **landscape-first** — no redesign of the game canvas.
- **D-05:** The "rotate your phone" nudge fires **after the player taps Play** from the home page (not on the home page itself, which is portrait). Nudge triggers when `vw < 480 && vh > vw * 1.3` (existing logic is fine, just ensure it only activates post-launch).
- **D-06:** Future games may be designed portrait-native — the shell must not assume all games are landscape.

### HUD on Small Screens

- **D-07:** On narrow screens (≤ 480px wide), the HUD **collapses to essentials**: attempt dots, countdown timer, and the hamburger menu icon only.
- **D-08:** Prize description, rank, best score, and avatar are hidden from the HUD on narrow screens and accessible via the menu panel instead.
- **D-09:** The HUD height should remain consistent (56px target) so `resizeCanvas()` calculations don't break.

### Controls Layout

- **D-10:** Controls are **redesigned for thumb reach** — anchor to the bottom of the **viewport** (not the canvas bottom), so they sit at the very bottom of the screen regardless of how the canvas is scaled.
- **D-11:** Controls must meet the 44×44px minimum tap target on a 375px-wide screen. Verify clamp values hit this minimum and increase if needed.
- **D-12:** Safe-area insets (`env(safe-area-inset-bottom)`) applied to the controls container so they don't sit under the iOS home indicator or Android gesture bar.

### PWA Manifest

- **D-13:** `manifest.json` app name: **"miniGameshow"** (working title, easy to change when brand finalizes).
- **D-14:** Icon: crop from existing `prototypes/assets/pengu-sheet.png` — the "happy" pose. Generate at minimum 192×192 and 512×512 PNG versions.
- **D-15:** `display: "standalone"`, `orientation: "any"` (home shell is portrait, game is landscape — don't lock either at manifest level).
- **D-16:** Theme color: `#2A1A0E` (dark brown, matches CSS `--dark` variable in game).

### Load Performance

- **D-17:** Pin Supabase JS CDN to a specific version (e.g., `@supabase/supabase-js@2.x.x`) — no floating `@latest`. Add SRI integrity hash.
- **D-18:** Font preloads (`Titan One`, `Bubblegum Sans`) should have `crossorigin` and `as="font"` attributes to avoid FOUT.

### Claude's Discretion

- Exact breakpoint for HUD collapse (somewhere around 480px is fine — Claude decides exact value based on HUD content fit)
- Whether the home page is a new `index.html` or a JS-rendered state — Claude picks the simpler approach consistent with existing no-build-step architecture
- Exact clamp() values for controls as long as minimums are met
- How icons are generated from the sprite sheet (ImageMagick, Canvas API, or manual crop — whatever's fastest)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Existing game shell
- `prototypes/penguin-game.html` §Canvas sizing (lines ~1146–1200) — existing `resizeCanvas()` logic, NATIVE_W/H values, HUD height dependency
- `prototypes/hud.js` — HUD IIFE module, public API including `height()` method
- `prototypes/hud.css` — HUD styles, existing responsive patterns
- `vercel.json` — current route rewrites (routes `/` to `/penguin-game.html` — this changes in Phase 1)

### Project specs
- `.planning/REQUIREMENTS.md` §Shell & Mobile Experience (SHEL-01–05) — acceptance criteria for this phase
- `.planning/PROJECT.md` — core constraints (3-second load, 375px minimum, no install required)
- `.planning/codebase/CONCERNS.md` §CDN risk — Supabase JS CDN version pinning (SECU-03)

### Design reference
- `GAME_BIBLE.md` §3 The Feeling, §5 The World — tone/color guidance for the home shell design
- `prototypes/assets/pengu-sheet.png` — source for PWA icon generation

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `resizeCanvas()` in `penguin-game.html`: already handles HUD height offset, resize events, orientation change — Phase 1 must preserve this contract
- `window.GameshowHud.height()`: used by canvas sizing — HUD changes must not break this
- CSS custom properties (`--teal`, `--yellow`, `--dark`, etc.): use these for home shell styling, don't introduce new colors

### Established Patterns
- No build pipeline — all files served directly from `prototypes/`. New files go in `prototypes/`.
- IIFE module pattern for shared code (`hud.js` → `window.GameshowHud`) — if home shell needs shared logic, follow same pattern
- `clamp()` for responsive sizing — already used in controls, continue this approach
- `env(safe-area-inset-*)` is NOT currently used — Phase 1 introduces it for controls bottom padding

### Integration Points
- `vercel.json` route rewrite: changing `/` from `penguin-game.html` to a new home shell requires updating this file
- `window.GameshowHud.init()` is called by the game — home shell may also need HUD or its own header
- HUD `height()` return value is hardcoded fallback at 56px — any HUD height change needs this fallback updated too

</code_context>

<specifics>
## Specific Ideas

- The gameshow home page is the "TV show title card" moment — portrait, bold, event info front and center
- Controls should feel like they're designed for thumbs at the bottom of the screen — not floating over the game world
- The rotate nudge is an invitation, not a wall — "landscape is better" after tapping Play, not a blocker

</specifics>

<deferred>
## Deferred Ideas

- Individual game-level portrait support (some future games will be portrait-native — design that per-game, not here)
- Animated splash screen or loading transition between home shell and game
- Home page with full event details, leaderboard preview, social share — that's Phase 3+ content; Phase 1 home shell is layout/shell only

</deferred>

---

*Phase: 01-phone-first-shell-pwa*
*Context gathered: 2026-04-02*
