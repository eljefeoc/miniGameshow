# Coding Conventions

**Analysis Date:** 2026-04-02

## Language & Runtime Profile

This is a no-build, no-framework, no-TypeScript codebase. All source is vanilla JavaScript
(ES2020+) and CSS running directly in the browser. One server-side file
(`scripts/vercel-write-supabase-config.mjs`) uses ES module syntax with Node.js.

No linting tools (ESLint, Biome) and no formatting tools (Prettier) are configured.
There is no `tsconfig.json`, no `.editorconfig`, and no `.prettierrc`. The only tooling
gate is `'use strict'` added at the top of inline game scripts.

---

## Naming Patterns

**Files:**
- HTML prototypes: kebab-case (`penguin-game.html`, `fish-stack.html`, `deep-dive.html`)
- Scripts: kebab-case with descriptive intent (`vercel-write-supabase-config.mjs`)
- Shared assets: lowercase with hyphens (`hud.js`, `hud.css`, `supabase-config.js`)

**CSS Classes:**
- Shared HUD component: `ghud-` prefix on all classes (`ghud-prize`, `ghud-stat-label`, `ghud-dot-used`)
- Per-game classes in the same file: no prefix, descriptive nouns (`thumb-btn`, `hud-cell`, `babs-zone`)
- State modifier classes: adjective suffixes (`badge-active`, `badge-upcoming`, `ghud-avatar.guest`)
- Admin page classes: semantic names without prefix (`card`, `btn`, `btn-primary`, `btn-danger`, `badge`)

**CSS IDs:**
- HUD component root IDs: `ghud-` prefix (`ghud-rank`, `ghud-schedule`, `ghud-avatar`)
- Game element IDs: descriptive nouns, no prefix (`overlay`, `btn-jump`, `cast-ring`, `canvas-wrap`)
- Admin element IDs: `f-` prefix for form inputs (`f-prize`, `f-ends`, `f-game`, `f-seed`)

**JavaScript — Functions:**
- camelCase throughout (`renderDots`, `fetchActiveWeek`, `submitRunToSupabase`, `updatePreview`)
- Private helper convention in IIFE modules: underscore prefix (`_clearInterval`, `_menuHandler`)
- Short one-letter parameters for tight loops and inline helpers (`n`, `d`, `e`, `t`)

**JavaScript — Variables:**
- Module-scoped state: underscore prefix when inside IIFE (`_showAt`, `_prizeName`, `_rank`)
- Top-level game state: plain camelCase (`score`, `fishCount`, `playMode`, `attemptsUsed`)
- Constants: ALL_CAPS for physics/tuning (`NATIVE_W`, `NATIVE_H`, `BREATH_MAX`, `GAME_VERSION`)
- CSS custom properties: `--ghud-` prefix in HUD, `--` + semantic name in games (`--teal`, `--yellow`, `--bg`)

---

## Module Design

**Shared modules** are wrapped in an IIFE that returns a public API object:
```js
const GameshowHud = (() => {
  // private state
  let _showAt = null;

  // private helpers
  function renderSchedule() { … }

  // public API
  function init(mountSelector) { … }
  function setStats({ rank, best, attemptsUsed } = {}) { … }

  return { init, setStats, setPrize, setShowAt, … };
})();
window.GameshowHud = GameshowHud;  // always assigned to window
```
Source: `prototypes/hud.js`

**Inline game scripts** use a top-level `'use strict';` declaration followed by flat
top-level functions and variables. There is no explicit module boundary — the entire
script block is one execution context.
Source: `prototypes/penguin-game.html` (line 1137), `prototypes/fish-stack.html` (line 233),
`prototypes/deep-dive.html` (line 312)

**Admin page** uses a `<script type="module">` block that imports Supabase dynamically via CDN
and organizes all logic in a single `async function boot()` which is called at the end:
```js
boot().catch(console.error);
```
Source: `prototypes/admin.html` (line 434)

---

## Code Style

**Formatting — No enforced tooling.** Observed de-facto style varies by file:

| File | Indentation | Brace style |
|------|-------------|-------------|
| `hud.js` | 2 spaces | BSD/Allman for functions, K&R for conditions |
| `penguin-game.html` (inline JS) | 2 spaces, compact on single lines | K&R, often single-line ternary chains |
| `admin.html` (inline JS) | 2 spaces, compact | K&R, everything on one line when short |
| `deep-dive.html` (inline JS) | 2 spaces, `var` keyword | K&R |

**Note:** `deep-dive.html` uses `var` declarations and older patterns throughout. All other
JS files use `const`/`let`.

**Whitespace:**
- CSS in `hud.css`: property per line, 2-space indent
- CSS in HTML `<style>` blocks: compact single-line rules when possible (`display:flex; align-items:center;`)
- Blank lines used to separate logical sections with comment banners

---

## Section Banners / Comments

All major logical sections inside scripts are delimited with ASCII box comments:
```js
// ═══════════════════════════════════════════════════════════
//  SECTION NAME — short description
// ═══════════════════════════════════════════════════════════
```

Subsections inside those use lighter rules:
```js
// ── public API ───────────────────────────────────────────
```

CSS sections use the same `/* ── label ────────────────────── */` style.

File headers are multi-line JSDoc-style blocks:
```js
/* ============================================================
   MiniGameshow — Component Name
   Description of usage.
   ============================================================ */
```
Source: `prototypes/hud.js` (lines 1–18)

---

## Import Organization

No bundler or import maps. Script dependencies are loaded via:

1. **HTML `<script src="…">`** — for same-directory shared modules (`hud.js`)
2. **Dynamic `import('https://cdn.jsdelivr.net/…')`** inside `async` functions — for Supabase JS client
3. **No import statements** in inline game scripts; everything uses `window.*` globals

The `window.__MINIGAMESHOW_SUPABASE__` global carries Supabase credentials injected at
build time. The Supabase client is stored on `window._miniGameshowSb` after initialization.

---

## Error Handling

**Async / Supabase calls:** All `async` functions wrap Supabase calls in `try/catch`.
Errors are logged with a prefixed label then silently swallowed to keep the game running:
```js
}catch(e){ console.error('fetchActiveWeek', e); }
```
Source: `prototypes/penguin-game.html` (lines 1775, 1789, 1803)

**Audio / vibration:** Web Audio and vibration calls are individually wrapped in silent
try/catch to prevent crashes on unsupported platforms:
```js
try{ navigator.vibrate(pattern); }catch(e){}
```
Source: `prototypes/penguin-game.html` (lines 1207–1209)

**Guard clauses:** Early-return null-checks before DOM access are used consistently:
```js
function renderDots(used) {
  const wrap = el('ghud-attempts');
  if (!wrap) return;
  …
}
```
Source: `prototypes/hud.js`

**Supabase insert errors:** On DB write failure the game shows the error in a visible
tip element rather than alerting, keeping UX flow intact.
Source: `prototypes/penguin-game.html` (lines 2718–2723)

---

## Logging

No structured logging library. Three patterns are used:

- `console.warn(label, detail)` — HUD mount not found (non-fatal, one location)
- `console.error(label, error)` — Async catch blocks throughout `penguin-game.html`
- `console.log('[script-name] message')` — Build step success in `scripts/vercel-write-supabase-config.mjs`

---

## HTML / DOM Conventions

**Selector strategy:** `document.getElementById(id)` via a local alias `el(id)` in `hud.js`;
direct `document.getElementById(id)` calls everywhere else. No `querySelector` for ID lookups.

**Inline styles:** Used freely for dynamic state (`display`, `color`, `textContent`). Static
appearance always lives in `<style>` or `.css` files.

**Event listeners:** `addEventListener` for all user interaction. No inline `onclick=` except
one deliberate case in admin for table row edit buttons using `window._editWeek(id)` (required
because rows are generated via innerHTML).

**Accessibility:** `role="button"`, `tabindex="0"`, `aria-label` are applied to non-button
interactive elements in `hud.js`. Game prototype buttons use semantic `<button>` elements.
`aria-label` on canvas-overlay buttons. No ARIA elsewhere.

---

## CSS Conventions

**Design tokens:** Each file defines its own `:root` CSS custom properties. The HUD uses
`--ghud-h: 56px` for height sharing with JS (`GameshowHud.height()`). Game files each
define a local palette (`--teal`, `--yellow`, `--brown`, etc.). There is no shared design
token file.

**Typography:** Google Fonts loaded via `<link>` in HTML. Game-specific fonts (`Press Start 2P`,
`Fredoka One`, `Bubblegum Sans`, `Titan One`) used contextually. System font stacks as
fallback: `system-ui, -apple-system, sans-serif`.

**Responsive:** `clamp()` used for font sizes and button dimensions. `@media (max-width: 480px)`
breakpoint used in `hud.css` to hide rank column on narrow viewports.

**Transitions:** Short `transition` declarations on interactive elements: `0.15s` for hovers,
`0.1s` for active press states. Animations use `@keyframes` for UI flourishes.

---

## Function Design

- Functions are small and single-purpose where possible (e.g., `el()`, `fmtNum()`, `fmtShowTime()`)
- Game-loop functions can be long (100–200 lines) because they manage a full frame lifecycle
- Destructuring with defaults is used for public API parameters:
  ```js
  function setStats({ rank = null, best = null, attemptsUsed = 0 } = {}) { … }
  ```
- Optional chaining `?.` and nullish coalescing `??` are used throughout modern files
- Ternary chains are preferred over if/else for compact conditional rendering

---

## SQL Conventions (`supabase/`)

- Tables: `snake_case` (`games`, `weekly_runs`, `daily_attempts`)
- Columns: `snake_case`, explicit `NOT NULL DEFAULT` where applicable
- Primary keys: `uuid` via `gen_random_uuid()`
- Timestamps: `timestamptz NOT NULL DEFAULT now()`
- Constraints: named with `tablename_constraint_suffix` pattern
- Migrations: timestamp-prefixed filenames (`20250327120000_initial_schema.sql`)
- Comments in SQL use `-- Section label` dashes

---

*Conventions analysis: 2026-04-02*
