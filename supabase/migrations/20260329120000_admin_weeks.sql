-- MiniGameshow — Admin / Weeks enhancement migration
-- Apply via Supabase SQL Editor or: supabase db push
--
-- Adds:
--   weeks.show_at           — timestamptz of the live show
--   weeks.show_url          — optional stream link shown in HUD/admin
--   weeks.prize_description — longer prize copy for share cards / admin
--   profiles.is_admin       — flag to gate the admin panel
--   RLS policies            — authenticated admin can INSERT / UPDATE weeks
-- -------------------------------------------------------------------------

-- ── weeks: new columns ────────────────────────────────────────────────────
ALTER TABLE public.weeks
  ADD COLUMN IF NOT EXISTS show_at           timestamptz,
  ADD COLUMN IF NOT EXISTS show_url          text,
  ADD COLUMN IF NOT EXISTS prize_description text;

-- ── profiles: admin flag ──────────────────────────────────────────────────
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS is_admin boolean NOT NULL DEFAULT false;

-- ── RLS: allow admins to create and edit competition weeks ────────────────
-- (anon/player read is already covered by weeks_select_all)

CREATE POLICY "weeks_insert_admin"
  ON public.weeks FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "weeks_update_admin"
  ON public.weeks FOR UPDATE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  )
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

-- ── Set your own account as admin ─────────────────────────────────────────
-- After running this migration, go to Supabase → Table Editor → profiles,
-- find your row and set is_admin = true. Or run:
--
--   UPDATE public.profiles
--   SET is_admin = true
--   WHERE id = '<your-auth-user-uuid>';
