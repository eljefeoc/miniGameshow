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

## Local vs Vercel

Local dev still uses `prototypes/supabase-config.js` you create from `supabase-config.example.js`; Vercel does not use that file from git — it regenerates it on build.
