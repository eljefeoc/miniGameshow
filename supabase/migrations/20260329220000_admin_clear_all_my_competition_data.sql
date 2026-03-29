-- Destructive admin stress-test: remove ALL competition rows for the signed-in admin user
-- across every game/week (runs, leaderboard, daily_attempts). Replaces the pengu-fisher-only RPC.

DROP FUNCTION IF EXISTS public.admin_clear_my_pengu_fisher_data();

CREATE OR REPLACE FUNCTION public.admin_clear_all_my_competition_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  n_lb int;
  n_runs int;
  n_da int;
  n_ev int;
  w record;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p WHERE p.id = uid AND p.is_admin = true
  ) THEN
    RAISE EXCEPTION 'Admin only';
  END IF;

  -- Leaderboard references runs (best_run_id RESTRICT) — remove first
  DELETE FROM public.leaderboard WHERE user_id = uid;
  GET DIAGNOSTICS n_lb = ROW_COUNT;

  DELETE FROM public.runs WHERE user_id = uid;
  GET DIAGNOSTICS n_runs = ROW_COUNT;

  DELETE FROM public.daily_attempts WHERE user_id = uid;
  GET DIAGNOSTICS n_da = ROW_COUNT;

  DELETE FROM public.content_events
  WHERE metadata ? 'user_id'
    AND (metadata->>'user_id')::uuid = uid;
  GET DIAGNOSTICS n_ev = ROW_COUNT;

  FOR w IN SELECT id FROM public.weeks
  LOOP
    PERFORM public.refresh_leaderboard_ranks(w.id);
  END LOOP;

  RETURN jsonb_build_object(
    'leaderboard_rows_deleted', n_lb,
    'runs_deleted', n_runs,
    'daily_attempt_rows_deleted', n_da,
    'content_events_deleted', n_ev
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_clear_all_my_competition_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_clear_all_my_competition_data() TO authenticated;

-- RLS: allow JWT user to delete content_events rows tagged with their user_id (RPC runs as invoker for RLS)
DROP POLICY IF EXISTS "content_events_delete_own_meta" ON public.content_events;
CREATE POLICY "content_events_delete_own_meta"
  ON public.content_events FOR DELETE
  TO authenticated
  USING (
    metadata ? 'user_id'
    AND (metadata->>'user_id')::uuid = auth.uid()
  );
