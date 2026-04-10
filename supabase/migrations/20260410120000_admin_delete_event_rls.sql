-- Allow admins to delete competition data for any player so a full event teardown
-- (leaderboard → runs → event) works under RLS.
--
-- events: older DBs may have weeks_delete_admin (from 202603301 on weeks, survives
-- rename to events). This migration adds a clearly named policy; having both is fine.

DROP POLICY IF EXISTS "events_delete_admin" ON public.events;
CREATE POLICY "events_delete_admin"
  ON public.events FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

DROP POLICY IF EXISTS "runs_delete_admin" ON public.runs;
CREATE POLICY "runs_delete_admin"
  ON public.runs FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

DROP POLICY IF EXISTS "leaderboard_delete_admin" ON public.leaderboard;
CREATE POLICY "leaderboard_delete_admin"
  ON public.leaderboard FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );
