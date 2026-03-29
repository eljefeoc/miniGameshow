# Deploy to Vercel

## One-time setup

1. Push this repo to GitHub (if it is not already).
2. In [Vercel](https://vercel.com) → **Add New Project** → import **`miniGameshow`**.
3. Leave **Root Directory** as the repo root (default). Vercel reads `vercel.json`.
4. Under **Environment Variables**, add (Production / Preview as you like):
   - **`SUPABASE_URL`** — Supabase project URL  
   - **`SUPABASE_ANON_KEY`** — Supabase **anon public** key (not `service_role`)
5. Deploy.

The build runs `npm run build`, which writes `prototypes/supabase-config.js` from those variables. That file is gitignored locally but is created on each Vercel build.

## URLs

- **`/`** → Pengu Fisher (`penguin-game.html`)
- **`/admin.html`** → Admin panel
- **`/penguin-game.html`** → same game (direct)

## Supabase Auth (required for sign-in on the live URL)

In Supabase → **Authentication** → **URL configuration**:

- **Site URL:** `https://<your-project>.vercel.app`
- **Redirect URLs:** add `https://<your-project>.vercel.app/**` (and preview URLs if you use them, e.g. `https://*.vercel.app/**` for previews — use only if you accept that scope).

## Local vs Vercel

Local dev still uses `prototypes/supabase-config.js` you create from `supabase-config.example.js`; Vercel does not use that file from git — it regenerates it on build.
