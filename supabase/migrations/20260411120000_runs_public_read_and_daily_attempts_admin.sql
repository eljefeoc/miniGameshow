-- Public read of runs for leaderboard UIs (game + admin list by score).
-- Clients should select only non-sensitive columns; RLS cannot column-filter.
-- Admin read of all players' daily_attempts for attempt dots in admin.

DROP POLICY IF EXISTS "runs_select_leaderboard_public" ON public.runs;
CREATE POLICY "runs_select_leaderboard_public"
  ON public.runs FOR SELECT
  TO anon, authenticated
  USING (true);

DROP POLICY IF EXISTS "daily_attempts_select_admin" ON public.daily_attempts;
CREATE POLICY "daily_attempts_select_admin"
  ON public.daily_attempts FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );
