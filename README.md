# miniGameshow

Mini game show — PWA + canvas games, Supabase backend.

---

## Step 0 — Check for conflicts (before running `schema.sql`)

Use your **production** Supabase project if you want one database for launch. You only need a **separate** project if this database is for something else or you want staging vs prod.

### What “conflict” means

Our schema creates **tables** (`games`, `profiles`, `weeks`, …), **functions**, and a **trigger** on `auth.users`. If something with the **same name** already exists and was built for a different purpose, running `schema.sql` can **fail** or **overwrite** behavior.

### How to check (Supabase Dashboard)

1. Open your project → **SQL Editor** → **New query**.
2. Paste and run everything in **`supabase/pre_flight_check.sql`**.
3. Read the results:

| Query | Empty result | Non-empty result |
|--------|----------------|------------------|
| **(1) Table names** | None of our tables exist yet — safe to apply full `schema.sql`. | One or more names appear — those tables already exist. **Stop.** Either use a different project, or drop/rename the old tables (only if you’re sure nothing else needs them), or adjust our schema names (advanced). |
| **(2) Function names** | No conflicting functions. | Same-named functions exist — applying our schema may fail on `CREATE FUNCTION`. Resolve before re-running. |
| **(3) Triggers on `auth.users`** | No trigger yet, or only unrelated ones. | If `on_auth_user_created` already exists, our script will fail on `CREATE TRIGGER`. Rename or drop the old trigger first, or merge logic manually. |

### Quick rule of thumb

- **Brand-new empty project** → no conflict check needed; run `schema.sql`.
- **Project already used for other apps** → run `pre_flight_check.sql` first.

---

## Step 1 — Apply the database schema

1. **SQL Editor** → **New query** → paste the full contents of **`supabase/schema.sql`** → **Run**.
2. Confirm success (no errors).
3. **Optional:** copy **Project URL** and **anon public** key into **`.env`** at repo root (see **`.env.example`**) for server-side tools later.

You should see tables including `games`, `profiles`, `weeks`, `runs`, `leaderboard`, `daily_attempts`, `content_events`, and a seed row for `pengu-fisher` in `games`.

4. **Insert your first week** (required before real score runs): in **SQL Editor**, run **`supabase/seed_week.sql`** (current ISO week for `pengu-fisher`, idempotent). Or use the example at the bottom of `schema.sql` / **Table Editor → `weeks`**.

---

## Step 2 — Supabase Auth (email) + prototype wiring

This enables **sign up / sign in** in the browser so later steps can attach **JWT-authenticated** requests to your API.

### A. Dashboard settings (do this once per project)

1. **Authentication → Providers → Email** — ensure **Email** is enabled (default on many projects).
2. **Authentication → URL configuration**
   - **Site URL:** set to where you open the game, e.g. `http://localhost:8080` while developing, and your real domain when deployed.
   - **Redirect URLs:** add the same origins you use (e.g. `http://localhost:8080/**`, `http://127.0.0.1:5500/**`). Without this, email confirmation links can break when you add them later.

### B. Local config for the HTML prototype (no build step)

1. From the repo root:
   ```bash
   cp prototypes/supabase-config.example.js prototypes/supabase-config.js
   ```
2. Edit **`prototypes/supabase-config.js`** and paste:
   - **Project URL** → `url`
   - **anon public** key → `anonKey`  
   Never commit this file (it is gitignored). Never put the **service_role** key here.

3. Serve the folder over HTTP (required for ES modules used by the Supabase client), e.g.:
   ```bash
   cd prototypes && python3 -m http.server 8080
   ```
4. Open **`http://localhost:8080/penguin-game.html`** (not `file://`).

### C. What the prototype does

- **`penguin-game.html`** loads `supabase-config.js`, then connects with **`@supabase/supabase-js`** (dynamic `import` from CDN).
- You get a small **Account** panel: **email**, **password**, **Sign up**, **Sign in**, **Sign out**.
- Successful sign-up creates **`auth.users`**; our SQL trigger creates **`public.profiles`** automatically.

If keys are missing, the panel shows a short reminder to add `supabase-config.js`.

---

## Repo layout (Supabase)

| Path | Purpose |
|------|---------|
| `supabase/schema.sql` | Full schema — paste in SQL Editor |
| `supabase/migrations/20250327120000_initial_schema.sql` | Same SQL for `supabase db push` |
| `supabase/pre_flight_check.sql` | Conflict check queries (step 0) |
| `supabase/config.toml` | Supabase CLI / local dev |
| `.env.example` | Template for server-side env vars |
| `prototypes/supabase-config.example.js` | Template for browser prototype keys |

---

## CLI (optional)

Install the [Supabase CLI](https://supabase.com/docs/guides/cli), then `supabase link` and `supabase db push` if you prefer migrations over pasting SQL.
