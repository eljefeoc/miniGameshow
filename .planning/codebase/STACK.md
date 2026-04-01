# Technology Stack

**Analysis Date:** 2026-04-02

## Languages

**Primary:**
- HTML5 / CSS3 / Vanilla JavaScript (ES2020+, ESM) — all game UI, game logic, admin panel, and HUD in `prototypes/`
- SQL (PostgreSQL dialect) — all database schema, migrations, triggers, and RLS policies in `supabase/`

**Secondary:**
- Node.js (ESM) — build script only: `scripts/vercel-write-supabase-config.mjs`
- CSS3 — game and HUD styling via `prototypes/hud.css` and inline `<style>` blocks in HTML files

## Runtime

**Environment:**
- Browser — primary runtime; no bundler, no transpilation; ES modules loaded via `<script type="module">` or dynamic `import()`
- Node.js — used only for the Vercel pre-deploy build step (`npm run build`)

**Local Dev Server:**
- Any static file server works; documented approach is `python3 -m http.server 8080` from `prototypes/`
- ES modules require HTTP (not `file://`); no dev server tooling is bundled

## Frameworks

**Core:**
- None — all game and UI code is hand-written vanilla JS on an HTML5 `<canvas>`; no React, Vue, Angular, or any SPA framework

**Game Engine:**
- None — rendering uses the native HTML5 `<canvas>` 2D API directly in `prototypes/penguin-game.html`

**Supabase Local Dev:**
- Supabase CLI v2.84.2 (noted in `supabase/.temp/cli-latest`) — local Postgres + Auth + Studio + Realtime stack
- Deno v2 — used by Supabase Edge Runtime (configured in `supabase/config.toml`)

**Testing:**
- Not detected — no test framework, test runner, or test files are present

**Build/Dev:**
- `npm run build` → `node scripts/vercel-write-supabase-config.mjs` — writes `prototypes/supabase-config.js` from env vars at deploy time; only Node built-ins (`fs`, `path`, `url`) used

## Key Dependencies

**Runtime (CDN-loaded, not npm-installed):**
- `@supabase/supabase-js@2` — loaded dynamically in browser from `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm`
  - Used in `prototypes/penguin-game.html` (line 2634) and `prototypes/admin.html` (line 681)
  - Provides `createClient`, Auth (email/password), and PostgREST query API

**Fonts (CDN-loaded):**
- Google Fonts — `Press Start 2P`, `Titan One`, `Bubblegum Sans`, `Fredoka One`, `Nunito`, `Cinzel` — loaded via `<link>` preconnect + stylesheet tags across HTML prototypes; no local font files

**Node.js (no external npm dependencies):**
- `package.json` declares no `dependencies` or `devDependencies`
- Build script uses only Node core modules: `fs`, `path`, `url`

## Configuration

**Environment:**
- Required vars: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
- Template: `.env.example` at repo root
- Local browser config: `prototypes/supabase-config.js` (gitignored), created from `prototypes/supabase-config.example.js`
- On Vercel: `scripts/vercel-write-supabase-config.mjs` generates `prototypes/supabase-config.js` at build time from env vars
- Config is exposed to the browser as `window.__MINIGAMESHOW_SUPABASE__ = { url, anonKey }`

**Build:**
- `package.json` — `"type": "module"`, `"build": "node scripts/vercel-write-supabase-config.mjs"`
- `vercel.json` — sets `buildCommand: "npm run build"`, `outputDirectory: "prototypes"`, rewrites `/` → `/penguin-game.html`

**Database:**
- `supabase/config.toml` — Supabase CLI local dev config; project_id: `miniGameshow`, Postgres major version 17, local API port 54321, DB port 54322, Studio port 54323
- `supabase/schema.sql` — canonical schema (apply via SQL Editor or CLI)
- `supabase/migrations/` — migration files for `supabase db push`
- `supabase/seed_week.sql` — idempotent week seed for current competition window
- `supabase/pre_flight_check.sql` — conflict detection queries for existing projects

## Package Management

**Manager:** npm
- `package.json` present at repo root; no lockfile (no npm dependencies to lock)
- No `node_modules` used at runtime — all browser dependencies are CDN-loaded

## Platform Requirements

**Development:**
- Node.js (any modern version supporting ESM) — only needed to run the build script
- Supabase CLI v2+ — optional, for local DB dev with `supabase link` / `supabase db push`
- A modern browser — no legacy browser support; targets ES2020+ and CSS custom properties

**Production:**
- Vercel — static hosting; serves `prototypes/` as the output directory
- Supabase hosted project — PostgreSQL 17, Auth (email), Realtime, Row Level Security

---

*Stack analysis: 2026-04-02*
