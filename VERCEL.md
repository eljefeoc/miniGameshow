# Deploy to Vercel

## One-time setup

1. Push this repo to GitHub (if it is not already).
2. In [Vercel](https://vercel.com) → **Add New Project** → import **`miniGameshow`**.
3. Leave **Root Directory** as the repo root (default). Vercel reads `vercel.json`.
4. Under **Environment Variables**, add (Production / Preview as you like):
   - **`SUPABASE_URL`** — Supabase project URL  
   - **`SUPABASE_ANON_KEY`** — Supabase **anon public** key (not `service_role`)
   - **`MINIGAMESHOW_SITE_URL`** (recommended for Production) — canonical origin with no trailing slash, e.g. `https://theminigameshow.com`. Auth confirmation emails use this for `emailRedirectTo` so links are not `localhost` when you once tested signup locally.
5. Deploy.

The build runs `npm run build`, which writes `prototypes/supabase-config.js` from those variables. That file is gitignored locally but is created on each Vercel build.

**Supabase Auth (confirmation links):** In the dashboard, set **Authentication → URL Configuration → Site URL** to the same canonical URL (`https://theminigameshow.com`). If **Site URL** stays `http://localhost:…`, some email templates still lean on that. **`MINIGAMESHOW_SITE_URL`** on Vercel fixes the in-app `emailRedirectTo`; **Site URL** fixes the server-side default.

**Canonical = pick one host and use it everywhere:** either **`https://theminigameshow.com`** (apex) **or** **`https://www.theminigameshow.com`** (www). Mixing them (Site URL apex but `MINIGAMESHOW_SITE_URL` with www, or the reverse) causes confusing redirects and extra SSL/domain config. Match Vercel’s **primary** domain.

**Verify what the live game uses:** Open the deployed `/penguin-game.html` → browser **DevTools → Console**. After load you should see  
`[MiniGameshow] Sign-up confirmation link redirect_to → https://…`  
You can also run **`__MINIGAMESHOW_CONFIRM_REDIRECT__`** in the console — it is the exact URL passed to Supabase on sign-up.

## URLs

- **`/`** → L1 home shell ([`index.html`](prototypes/index.html))
- **`/penguin-game.html`** → game (L2/L3)
- **`/admin.html`** → Admin panel

## Admin panel — database migration and Edge Functions

**SQL (bans, clear-scores, week delete, profile flags):** Apply migration [`supabase/migrations/20260330120000_admin_user_mgmt.sql`](supabase/migrations/20260330120000_admin_user_mgmt.sql) (SQL Editor or `supabase db push`).

### Edge Functions (user list / create / delete Auth users)

**Prerequisites:** [Supabase CLI](https://supabase.com/docs/guides/cli) installed, `supabase login`, and the project linked (`supabase link` or `supabase link --project-ref <ref>`).

**One-time secret** (Dashboard → **Settings** → **API** — use the **service_role** key; never commit it):

```bash
supabase secrets set SUPABASE_SERVICE_ROLE_KEY=<your_service_role_key>
```

**Redeploy** whenever `supabase/functions/` or [`supabase/config.toml`](supabase/config.toml) changes:

```bash
npm run deploy:functions
```

That runs [`scripts/deploy-supabase-functions.sh`](scripts/deploy-supabase-functions.sh), which deploys `admin-list-users`, `admin-auth-create-user`, and `admin-auth-delete-user`.

Deployed functions get `SUPABASE_URL` and `SUPABASE_ANON_KEY` from the project automatically. Auth is enforced in code (`requireAdmin`); [`supabase/config.toml`](supabase/config.toml) sets **`verify_jwt = false`** for those three so the API gateway does not return a bogus `Invalid JWT` before Deno runs. If you still see that error, check **Dashboard → Edge Functions →** each function **→ Verify JWT** is off (in case the dashboard overrode CLI config).

**Browser config:** only the **anon** key belongs in `supabase-config.js` / Vercel env. Optional: set `functionsUrl` if the functions base is not `{SUPABASE_URL}/functions/v1`.

### Admin panel — live leaderboard (Realtime)

The admin ([`prototypes/admin.html`](prototypes/admin.html)) subscribes to **`INSERT` on `public.runs`** so the competition leaderboard can update without a full page refresh. That requires **`public.runs`** to be part of the **`supabase_realtime` publication** for your project.

- **Supabase Dashboard** → **Database** → **Publications** (or **Settings → API → Realtime** depending on dashboard version) → ensure **`runs`** is enabled for Realtime, or run SQL such as: `alter publication supabase_realtime add table public.runs;` (skip if already listed).
- If Realtime is off or blocked, the admin still **polls** the leaderboard (10s while a competition event is **active** and you are on Live + Competition tab; otherwise 30s).

## Custom domain: Namecheap → Vercel (`theminigameshow.com`)

Use **DNS records** (Advanced DNS), not Namecheap’s **URL Redirect** for the same hostnames you want Vercel to serve—redirect records can fight HTTPS routing.

### 1. Add the domain in Vercel

1. [Vercel](https://vercel.com) → your **miniGameshow** project → **Settings** → **Domains**.
2. Enter **`theminigameshow.com`** → **Add**.
3. Add **`www.theminigameshow.com`** as well (optional but common).
4. Vercel shows the exact **DNS records** to create. Keep that tab open; values can differ slightly by project (always prefer what Vercel displays).

Typical pattern (confirm against Vercel’s UI):

| Purpose | Type | Host / Name | Value |
|--------|------|-------------|--------|
| Apex (`theminigameshow.com`) | **A** | `@` | `76.76.21.21` |
| `www` | **CNAME** | `www` | `cname.vercel-dns.com` |

### 2. Configure DNS in Namecheap

1. Namecheap → **Domain List** → **Manage** next to `theminigameshow.com`.
2. Open the **Advanced DNS** tab.
3. **Turn off** Namecheap’s **URL Redirect** / **Parking** for this domain if anything conflicts with `@` or `www`.
4. Under **Host records**, add or edit:
   - **A Record** — **Host** `@` — **Value** `76.76.21.21` — TTL **Automatic** (or 1 min while testing).
   - **CNAME Record** — **Host** `www` — **Value** `cname.vercel-dns.com` — TTL **Automatic**.
5. Remove old conflicting **A/CNAME** rows for `@` or `www` (e.g. parking IPs) if present.
6. Save. Propagation can take a few minutes to 48 hours; often under an hour.

### 3. Finish in Vercel

1. When DNS propagates, Vercel marks the domain **Valid**.
2. Set **one primary**: e.g. redirect `www.theminigameshow.com` → `https://theminigameshow.com` (or the reverse) in the Domains UI so links are consistent.

### 4. Point Supabase Auth at the custom domain

In Supabase → **Authentication** → **URL configuration**:

- **Site URL:** `https://theminigameshow.com` (use your **canonical** URL, with or without `www`, matching Vercel’s primary).
- **Redirect URLs:** include at least  
  `https://theminigameshow.com/**`  
  and, if you use `www`,  
  `https://www.theminigameshow.com/**`  
  Keep `http://localhost:*` entries if you still test locally.

### 5. Resend (optional but recommended)

In Resend → **Domains**, add **`theminigameshow.com`**, add the DNS records Resend gives you (often extra TXT/CNAME). Use a **From** like `auth@theminigameshow.com` in Supabase SMTP only after the domain is **verified** in Resend.

### Alternative: Vercel nameservers

If you prefer not to manage A/CNAME at Namecheap: in Namecheap → **Domain** → **Nameservers** → **Custom DNS**, set Vercel’s nameservers (shown in Vercel when you choose “Nameservers” setup). Then you add all DNS (apex, `www`, Resend, etc.) in **Vercel’s** DNS UI for that domain.

## Supabase Auth (required for sign-in on the live URL)

In Supabase → **Authentication** → **URL configuration** (before custom domain, use Vercel default):

- **Site URL:** `https://<your-project>.vercel.app` — switch to `https://theminigameshow.com` when the domain is live.
- **Redirect URLs:** add `https://<your-project>.vercel.app/**` and, after cutover, `https://theminigameshow.com/**` (and `www` if used).

## Supabase — Google, Apple, and phone (SMS)

The game ([`prototypes/penguin-game.html`](prototypes/penguin-game.html)) includes **Google**, **Apple**, and **SMS** sign-in. Each must be turned on and configured in the **Supabase Dashboard**; no extra API keys in the game repo.

### Redirect URL (all OAuth providers)

Supabase redirects to:  
`https://<your-project-ref>.supabase.co/auth/v1/callback`  

In **Google** / **Apple** developer consoles you register **that** callback URL (not your Vercel URL). Your **Site URL** and **Redirect URLs** in Supabase (see above) must still include your live game origin so users return to `https://www.theminigameshow.com/penguin-game.html` (or your canonical URL) after OAuth.

### Google

1. [Google Cloud Console](https://console.cloud.google.com/) → APIs & Services → **Credentials** → **Create credentials** → **OAuth client ID** (type **Web application**).
2. **Authorized redirect URIs:** add  
   `https://<project-ref>.supabase.co/auth/v1/callback`  
   (`project-ref` is in Supabase **Project Settings → API**.)
3. Supabase → **Authentication** → **Providers** → **Google** → enable, paste **Client ID** and **Client secret**.

### Apple

1. [Apple Developer](https://developer.apple.com/) → **Certificates, Identifiers & Profiles** → **Identifiers** → create a **Services ID** for “Sign in with Apple” (web).
2. Configure **Return URLs** with the same Supabase callback:  
   `https://<project-ref>.supabase.co/auth/v1/callback`
3. Create a **Key** for Sign in with Apple and note **Key ID**, **Team ID**, **private key**.
4. Supabase → **Authentication** → **Providers** → **Apple** → enable, paste **Services ID** (client ID), **Secret** (JWT / key per [Supabase Apple guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)).

### Phone (SMS)

1. Supabase → **Authentication** → **Providers** → **Phone** → enable.
2. Connect an SMS provider (**Twilio** is common): account SID, auth token, message service SID (or from number) per Supabase’s phone docs.
3. SMS costs and rate limits are billed by the provider; add **CAPTCHA** (Supabase **Auth → Attack protection**) if you see SMS abuse.

Phone users may have **no email**; the UI shows **phone** in the account strip and HUD where relevant.

## Local vs Vercel

Local dev still uses `prototypes/supabase-config.js` you create from `supabase-config.example.js`; Vercel does not use that file from git — it regenerates it on build.
