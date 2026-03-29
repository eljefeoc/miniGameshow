# miniGameshow

Mini game show — PWA + canvas games, Supabase backend.

## Supabase (step 1 — create project and apply schema)

Do this once per environment (e.g. dev project first).

1. **Create a project** at [supabase.com](https://supabase.com) (pick region, set a strong DB password).
2. **Apply the database schema**
   - **Dashboard:** open **SQL Editor** → **New query** → paste the full contents of `supabase/schema.sql` → **Run**. You should see success with no errors.
   - **CLI (optional):** install the [Supabase CLI](https://supabase.com/docs/guides/cli), then from this repo: `supabase link --project-ref <your-ref>` and `supabase db push` (uses `supabase/migrations/`).
3. **Copy API keys:** **Project Settings → API** → copy **Project URL** and **anon public** key into a local `.env` (see `.env.example`). Do not put the **service_role** key in the frontend.

After step 2, you should have tables `games`, `profiles`, `weeks`, `runs`, `leaderboard`, `daily_attempts`, `content_events`, plus the `pengu-fisher` row in `games`.

4. **Insert your first week** (required before score runs): uncomment and adjust the example `INSERT` at the bottom of `supabase/schema.sql`, or insert a row in **Table Editor → weeks** with a real `game_id` from `games`.

Repo layout:

- `supabase/schema.sql` — full schema (same SQL as the first migration file; good for copy-paste in the dashboard).
- `supabase/migrations/20250327120000_initial_schema.sql` — first migration for `supabase db push`.
- `supabase/config.toml` — local CLI / `supabase start` (from `supabase init`).
