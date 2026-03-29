-- Allow authenticated users to DELETE their own rows on tables that had no DELETE policies.
-- Without this, admin competition RPCs run as the JWT user for RLS and DELETE
-- match zero rows (RPC still succeeds with counts of 0).

DROP POLICY IF EXISTS "runs_delete_own" ON public.runs;
CREATE POLICY "runs_delete_own"
  ON public.runs FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "leaderboard_delete_own" ON public.leaderboard;
CREATE POLICY "leaderboard_delete_own"
  ON public.leaderboard FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

DROP POLICY IF EXISTS "daily_attempts_delete_own" ON public.daily_attempts;
CREATE POLICY "daily_attempts_delete_own"
  ON public.daily_attempts FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());
