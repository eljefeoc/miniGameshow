# External Integrations

**Analysis Date:** 2026-04-02

## APIs & External Services

**Backend-as-a-Service:**
- Supabase — primary data and auth backend for all game functionality
  - SDK/Client: `@supabase/supabase-js@2`, loaded at browser runtime via CDN: `https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2/+esm`
  - Auth env var: `SUPABASE_URL`, `SUPABASE_ANON_KEY`
  - Client instantiation: dynamic `import()` inside `prototypes/penguin-game.html` (~line 2634) and `prototypes/admin.html` (~line 681)
  - Config exposed to browser as `window.__MINIGAMESHOW_SUPABASE__ = { url, anonKey }` via `prototypes/supabase-config.js`

**CDN (jsDelivr):**
- `https://cdn.jsdelivr.net` — serves `@supabase/supabase-js@2` as an ES module at runtime; no local install

**Fonts:**
- Google Fonts — CDN delivery of `Press Start 2P`, `Titan One`, `Bubblegum Sans`, `Fredoka One`, `Nunito`, `Cinzel`
  - Loaded via `<link rel="preconnect" href="https://fonts.googleapis.com">` and stylesheet `<link>` tags across all HTML prototypes
  - Preconnect also established to `https://fonts.gstatic.com`

## Data Storage

**Databases:**
- Supabase / PostgreSQL 17 (hosted)
  - Connection: Supabase JS client using `SUPABASE_URL` + `SUPABASE_ANON_KEY`
  - Client: `@supabase/supabase-js@2` (browser PostgREST client; no server-side ORM)
  - Schema: `supabase/schema.sql` (canonical reference), `supabase/migrations/` (CLI migrations)
  - Tables:
    - `public.games` — game registry (slug, name)
    - `public.profiles` — extends `auth.users`; username, phone, country, is_banned
    - `public.weeks` — weekly competition windows (week_code, game_id, seed, starts_at, ends_at, prize_title, sponsor_name)
    - `public.runs` — score submissions (score, duration_ms, day_seed, input_count, input_log, frame_checkpoints, game_version, replay_payload, is_validated)
    - `public.leaderboard` — one row per user per week; tracks best_score, best_run_id, rank
    - `public.daily_attempts` — enforces max 5 runs per user per day_seed
    - `public.content_events` — event log populated by DB triggers (run_submitted, new_high_score); no consumer implemented yet
  - Row Level Security: enabled on all tables; users can only read/write their own `runs` and `daily_attempts`; `leaderboard`, `games`, `weeks` are public-read; `content_events` has no direct client access
  - Stored procedures: `before_run_insert` (validates user_id, enforces daily limit, sets attempt_num), `after_run_insert` (upserts leaderboard, refreshes ranks, writes content_events), `after_run_delete` (decrements attempts, recalculates leaderboard), `refresh_leaderboard_ranks` (dense rank by score), `handle_new_user` (trigger: creates profile on auth.users insert), `set_updated_at` (trigger: timestamps profiles)
  - Extension: `pgcrypto` (for `gen_random_uuid()`)

**File Storage:**
- Supabase Storage — enabled in `supabase/config.toml` (50 MiB limit, S3 protocol enabled), but no application code currently writes to or reads from storage buckets

**Caching:**
- None

## Authentication & Identity

**Auth Provider:**
- Supabase Auth — email/password sign-up and sign-in only
  - Browser implementation: `bootSupabaseAuth()` function in `prototypes/penguin-game.html` (~line 2615); matching flow in `prototypes/admin.html`
  - Auth trigger: `on_auth_user_created` (PostgreSQL trigger on `auth.users`) auto-creates a row in `public.profiles` on new user signup
  - JWT expiry: 3600 seconds (1 hour); refresh token rotation enabled (`refresh_token_reuse_interval = 10s`)
  - Session persistence: `persistSession: true`, `autoRefreshToken: true`, `detectSessionInUrl: true`
  - Anonymous sign-ins: disabled
  - Email confirmations: disabled by default in local config (`enable_confirmations = false`)
  - Minimum password length: 6 characters

**MFA:**
- Disabled (TOTP and phone MFA configured off in `supabase/config.toml`)

**OAuth / Social Providers:**
- Not enabled (Apple and all other external OAuth providers disabled in `supabase/config.toml`)

**Third-party Auth:**
- Firebase, Auth0, AWS Cognito, Clerk — all configured but disabled in `supabase/config.toml`

## Monitoring & Observability

**Error Tracking:**
- None — no Sentry, Datadog, Rollbar, or equivalent integration detected

**Logs:**
- `console.error` and `console.warn` used inline in game JS and build script
- Supabase Analytics backend: `postgres` (local dev only, configured in `supabase/config.toml`)

## CI/CD & Deployment

**Hosting:**
- Vercel — static site hosting
  - Config: `vercel.json`
  - Build command: `npm run build` (runs `scripts/vercel-write-supabase-config.mjs`)
  - Output directory: `prototypes/`
  - URL rewrites: `/` → `/penguin-game.html`; `/admin.html` and `/penguin-game.html` served directly
  - Docs: `VERCEL.md`

**CI Pipeline:**
- None — no GitHub Actions, CircleCI, or other CI configuration detected

## Environment Configuration

**Required env vars (Vercel project settings):**
- `SUPABASE_URL` — Supabase project URL (e.g. `https://<ref>.supabase.co`)
- `SUPABASE_ANON_KEY` — Supabase anon public API key (not service_role)

**Secrets location:**
- Production: Vercel project → Settings → Environment Variables
- Local: `prototypes/supabase-config.js` (gitignored); created by copying `prototypes/supabase-config.example.js` and filling in values

**Optional / future env vars (referenced in `supabase/config.toml`, not currently active):**
- `OPENAI_API_KEY` — Supabase Studio AI assistant (local dev only)
- `SUPABASE_AUTH_SMS_TWILIO_AUTH_TOKEN` — Twilio SMS auth (not enabled)
- `S3_HOST`, `S3_REGION`, `S3_ACCESS_KEY`, `S3_SECRET_KEY` — experimental OrioleDB/S3 storage (not enabled)

## Webhooks & Callbacks

**Incoming:**
- None — no webhook receiver endpoints detected

**Outgoing:**
- None — no outbound webhook calls detected; the `content_events` table is populated by DB triggers (`run_submitted`, `new_high_score`) for a future social/content pipeline, but no consumer is implemented

---

*Integration audit: 2026-04-02*
