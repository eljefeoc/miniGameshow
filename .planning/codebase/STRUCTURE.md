# Codebase Structure

**Analysis Date:** 2026-04-02

## Directory Layout

```
miniGameshow/                     # Repo root
├── prototypes/                   # All deployable game files (Vercel outputDirectory)
│   ├── assets/                   # Static assets (images, AI source files)
│   │   ├── pengu-sheet.png       # Penguin sprite sheet (500×500 PNG, 4 mood poses)
│   │   ├── PLAY-TO-WIN.png       # Welcome sticker image
│   │   └── PLAY-TO-WIN.ai        # Illustrator source for sticker
│   ├── penguin-game.html         # Game 01 — Pengu Fisher (live product, ~3094 lines)
│   ├── admin.html                # Operator admin panel — week management (~718 lines)
│   ├── hud.js                    # Shared Gameshow HUD module (exports window.GameshowHud, 308 lines)
│   ├── hud.css                   # Shared HUD styles (imported by all game HTML, 193 lines)
│   ├── supabase-config.js        # GITIGNORED — written at build time or manually for local dev
│   ├── supabase-config.example.js # Committed template showing expected shape
│   ├── welcome_sticker_v2.html   # Standalone sticker prototype/preview
│   ├── fish-stack.html           # Early prototype — Fish Stack game (standalone, gitignored)
│   └── deep-dive.html            # Early prototype — Deep Dive game (standalone, gitignored)
├── supabase/                     # Database schema, migrations, seed data
│   ├── schema.sql                # Full canonical schema — paste into Supabase SQL Editor
│   ├── migrations/               # Versioned migrations for `supabase db push`
│   │   ├── 20250327120000_initial_schema.sql
│   │   ├── 20260329120000_admin_weeks.sql
│   │   ├── 20260329180000_runs_delete_and_admin_clear.sql
│   │   ├── 20260329200000_rls_delete_own_rows.sql
│   │   ├── 20260329220000_admin_clear_all_my_competition_data.sql
│   │   └── 20260329230000_drop_admin_clear_all_my_competition_data.sql
│   ├── seed_week.sql             # Idempotent week seed (run after schema apply)
│   ├── pre_flight_check.sql      # Conflict detection queries (run before schema on existing projects)
│   ├── config.toml               # Supabase CLI project config
│   └── .temp/                    # Supabase CLI cache files (gitignored)
├── scripts/
│   └── vercel-write-supabase-config.mjs  # Build step: writes supabase-config.js from env vars
├── .planning/
│   └── codebase/                 # GSD mapping documents (ARCHITECTURE.md, STRUCTURE.md, etc.)
├── GAME_BIBLE.md                 # Product spec, design rules, character definitions (~49k chars)
├── README.md                     # Setup instructions (schema, auth, Supabase CLI, local dev)
├── VERCEL.md                     # Vercel deployment notes
├── vercel.json                   # Vercel config: build command, output dir, route rewrites
├── package.json                  # Minimal — name, type:module, build script only
├── .env.example                  # Template for env vars (SUPABASE_URL, SUPABASE_ANON_KEY)
├── .env                          # GITIGNORED — actual env vars (never commit)
└── .gitignore
```

---

## Directory Purposes

**`prototypes/`:**
- Purpose: Everything the browser loads. This is both the dev working directory and the Vercel output directory (`"outputDirectory": "prototypes"` in `vercel.json`)
- Contains: Game HTML files (self-contained), shared HUD module, static assets
- Key rule: Files here are served directly — no bundler, no framework, no routing beyond Vercel rewrites
- New games go here as new `.html` files

**`prototypes/assets/`:**
- Purpose: Static image assets loaded by `<img>` tags or `new Image()` in canvas code
- Contains: Sprite sheets (PNG), design source files (AI), promotional images
- New sprite sheets for new characters go here

**`supabase/`:**
- Purpose: All database definitions. The source of truth for the data layer.
- Contains: Schema (apply once), versioned migrations (for CLI workflow), seed data, conflict-check queries
- `supabase/schema.sql` and `supabase/migrations/20250327120000_initial_schema.sql` must stay in sync — schema.sql is the canonical full reference

**`scripts/`:**
- Purpose: Build-time tooling only
- Contains: `vercel-write-supabase-config.mjs` — the single build step; writes `prototypes/supabase-config.js` from `SUPABASE_URL` and `SUPABASE_ANON_KEY` env vars

**`.planning/codebase/`:**
- Purpose: GSD mapping documents for AI-assisted development; loaded by `/gsd:plan-phase` and `/gsd:execute-phase`
- Generated: By GSD tooling
- Committed: Yes (helps onboard future AI sessions)

---

## Key File Locations

**Primary game file:**
- `prototypes/penguin-game.html` — the only route served at `/`; the entire product

**Shared HUD:**
- `prototypes/hud.js` — module logic; IIFE exports `window.GameshowHud`
- `prototypes/hud.css` — styles; linked in `<head>` of every game HTML

**Admin:**
- `prototypes/admin.html` — served at `/admin.html`; requires `profiles.is_admin = true`

**Database schema:**
- `supabase/schema.sql` — canonical full schema (paste into SQL Editor for initial setup)
- `supabase/migrations/` — incremental migrations (for `supabase db push` workflow)

**Credential config:**
- `prototypes/supabase-config.example.js` — committed template; shape: `window.__MINIGAMESHOW_SUPABASE__ = { url: '...', anonKey: '...' }`
- `prototypes/supabase-config.js` — never commit; written by build script or developer manually for local dev
- `scripts/vercel-write-supabase-config.mjs` — writes the above from `SUPABASE_URL` + `SUPABASE_ANON_KEY`

**Product specification:**
- `GAME_BIBLE.md` — character definitions, mechanic rules, scoring design, visual language, DB schema spec (§8). Reference before changing game behavior.

**Deployment config:**
- `vercel.json` — sets `buildCommand: "npm run build"`, `outputDirectory: "prototypes"`, and root-route rewrite to `penguin-game.html`

---

## Naming Conventions

**Files:**
- Game HTML files: `kebab-case.html` (e.g., `penguin-game.html`, `fish-stack.html`)
- Shared modules: `lowercase.js` / `lowercase.css` (e.g., `hud.js`, `hud.css`)
- Config templates: `kebab-case.example.js`
- Build scripts: `kebab-case.mjs` (ES module)
- SQL migrations: `YYYYMMDDHHMMSS_description.sql` (Supabase CLI convention)

**JavaScript (inline in HTML):**
- Constants: `SCREAMING_SNAKE_CASE` (e.g., `NATIVE_W`, `GROUND_Y`, `GAME_VERSION`, `PENGU_FRAMES`)
- Game state variables: `camelCase` (e.g., `fishMeter`, `frenzyActive`, `playMode`, `attemptsUsed`)
- Functions: `camelCase` verbs (e.g., `resetGame`, `submitRunToSupabase`, `fetchActiveWeek`, `refreshTitleFirstPlayCard`)
- Private HUD state: `_camelCase` with leading underscore (e.g., `_showAt`, `_schedInterval`, `_menuHandler`)
- Short canvas helpers: brief lowercase (e.g., `el`, `rect`, `circ`, `rrect`, `t8`, `pr`)

**Database:**
- Tables: `snake_case` plural nouns (e.g., `runs`, `daily_attempts`, `content_events`)
- Functions: `snake_case` verbs (e.g., `after_run_insert`, `refresh_leaderboard_ranks`, `handle_new_user`)
- Triggers: `table_timing_verb` or `on_event_name` (e.g., `runs_before_insert`, `runs_after_delete`, `on_auth_user_created`)
- Indexes: `table_columns_idx` (e.g., `runs_user_week_idx`, `leaderboard_week_score_idx`)

**CSS classes:**
- Gameshow HUD: `ghud-` prefix (e.g., `ghud-stat`, `ghud-avatar`, `ghud-dot-used`, `ghud-urgent`)
- Game shell panel (menu overlay): `gsp-` prefix (e.g., `gsp-root`, `gsp-pane`, `gsp-lb-body`)
- First-play card: `fp-` prefix (e.g., `fp-stat`, `fp-avatar`, `fp-prize`, `fp-auth-embed`)
- In-game canvas HUD: `hud-` prefix (e.g., `hud-cell`, `hud-val`, `hud-lbl`, `hud-combo-val`)

---

## Where to Add New Code

**New game:**
1. Create `prototypes/new-game-name.html` (self-contained, following `penguin-game.html` pattern)
2. Include `<link rel="stylesheet" href="hud.css">` in `<head>` and `<script src="hud.js"></script>` before game script
3. Include `<script src="supabase-config.js"></script>` and the `window.__MINIGAMESHOW_SUPABASE__` safety stub
4. Mount HUD: `<div id="gameshow-hud-mount"></div>` + call `GameshowHud.init('#gameshow-hud-mount')`
5. Add a `slug` seed row to `supabase/schema.sql` and a new migration in `supabase/migrations/`
6. Add route to `vercel.json` rewrites if it should be accessible at a clean URL

**New shared UI component:**
- JavaScript module: `prototypes/component-name.js` (IIFE pattern → `window.ComponentName`, same as `hud.js`)
- Styles: `prototypes/component-name.css`

**New game assets (sprites, images):**
- Add to `prototypes/assets/`
- Reference with relative path `assets/filename.png` from HTML files in the same `prototypes/` directory

**New database table or column:**
- Create `supabase/migrations/YYYYMMDDHHMMSS_description.sql` with the changes
- Apply the same changes to `supabase/schema.sql` to keep it the canonical reference
- Test with `supabase db push` (CLI) or paste into SQL Editor
- Add RLS policies in the same migration — every table must have RLS enabled

**New competition week (operations, not code):**
- Use `prototypes/admin.html` (requires `profiles.is_admin = true`)
- Or run the commented INSERT at the bottom of `supabase/schema.sql`
- Or use `supabase/seed_week.sql` as a template

**New build-time script:**
- Add `.mjs` file to `scripts/`
- Wire into `package.json` `scripts` block
- Update `vercel.json` `buildCommand` if it needs to run on deployment

---

## Special Directories

**`prototypes/` (Vercel output):**
- Vercel `outputDirectory` — every file here is publicly accessible at the domain root
- Do NOT commit secrets here (`.gitignore` covers `supabase-config.js`)
- `supabase-config.js` is generated at build time by `scripts/vercel-write-supabase-config.mjs`

**`supabase/.temp/`:**
- Purpose: Supabase CLI temporary/cache files
- Generated: Yes (by Supabase CLI)
- Committed: No (in `supabase/.gitignore`)

---

## Module Boundaries

There are three distinct module boundaries in this codebase:

1. **`GameshowHud`** (`prototypes/hud.js`) — knows nothing about game logic, Supabase, or any specific game. Receives data via its public API. Can be dropped into any future game HTML unchanged.

2. **Game script** (inline in `prototypes/penguin-game.html`) — knows about `GameshowHud` (calls its API) and Supabase (uses `window._miniGameshowSb`). Contains all game-specific logic.

3. **Supabase database** (`supabase/schema.sql`) — enforces all business rules server-side (attempt limits, leaderboard maintenance, anti-cheat validation). The client cannot bypass these without the service role key, which is never exposed to the browser.

---

*Structure analysis: 2026-04-02*
