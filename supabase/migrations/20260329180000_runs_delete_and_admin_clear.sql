-- Keep daily_attempts + leaderboard consistent when runs are deleted (e.g. Table Editor).
-- Adds: after_run_delete trigger, admin-only RPC for stress-test reset.

-- ── After DELETE on runs: decrement daily_attempts; fix leaderboard if best run removed ──
CREATE OR REPLACE FUNCTION public.after_run_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_best_id uuid;
  v_best_score bigint;
BEGIN
  UPDATE public.daily_attempts
  SET attempts_used = GREATEST(0, attempts_used - 1),
      updated_at = now()
  WHERE user_id = OLD.user_id AND day_seed = OLD.day_seed;

  IF EXISTS (
    SELECT 1 FROM public.leaderboard
    WHERE user_id = OLD.user_id
      AND week_id = OLD.week_id
      AND best_run_id = OLD.id
  ) THEN
    SELECT r.id, r.score INTO v_best_id, v_best_score
    FROM public.runs r
    WHERE r.user_id = OLD.user_id AND r.week_id = OLD.week_id
    ORDER BY r.score DESC, r.created_at ASC
    LIMIT 1;

    IF v_best_id IS NULL THEN
      DELETE FROM public.leaderboard
      WHERE user_id = OLD.user_id AND week_id = OLD.week_id;
    ELSE
      UPDATE public.leaderboard
      SET best_score = v_best_score,
          best_run_id = v_best_id,
          updated_at = now()
      WHERE user_id = OLD.user_id AND week_id = OLD.week_id;
    END IF;

    PERFORM public.refresh_leaderboard_ranks(OLD.week_id);
  END IF;

  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS runs_after_delete ON public.runs;
CREATE TRIGGER runs_after_delete
  AFTER DELETE ON public.runs
  FOR EACH ROW
  EXECUTE FUNCTION public.after_run_delete();

-- ── Admin stress test: wipe signed-in admin's Pengu Fisher runs / LB / daily attempts ──
CREATE OR REPLACE FUNCTION public.admin_clear_my_pengu_fisher_data()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  uid uuid := auth.uid();
  gid uuid;
  n_lb int;
  n_runs int;
  n_da int;
  r record;
BEGIN
  IF uid IS NULL THEN
    RAISE EXCEPTION 'Not authenticated';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.profiles p WHERE p.id = uid AND p.is_admin = true
  ) THEN
    RAISE EXCEPTION 'Admin only';
  END IF;

  SELECT g.id INTO gid FROM public.games g WHERE g.slug = 'pengu-fisher' LIMIT 1;
  IF gid IS NULL THEN
    RAISE EXCEPTION 'Game pengu-fisher not found';
  END IF;

  DELETE FROM public.leaderboard l
  USING public.weeks w
  WHERE l.user_id = uid AND l.week_id = w.id AND w.game_id = gid;
  GET DIAGNOSTICS n_lb = ROW_COUNT;

  DELETE FROM public.runs r
  USING public.weeks w
  WHERE r.user_id = uid AND r.week_id = w.id AND w.game_id = gid;
  GET DIAGNOSTICS n_runs = ROW_COUNT;

  DELETE FROM public.daily_attempts WHERE user_id = uid;
  GET DIAGNOSTICS n_da = ROW_COUNT;

  FOR r IN SELECT w.id AS wid FROM public.weeks w WHERE w.game_id = gid
  LOOP
    PERFORM public.refresh_leaderboard_ranks(r.wid);
  END LOOP;

  RETURN jsonb_build_object(
    'leaderboard_rows_deleted', n_lb,
    'runs_deleted', n_runs,
    'daily_attempt_rows_deleted', n_da
  );
END;
$$;

REVOKE ALL ON FUNCTION public.admin_clear_my_pengu_fisher_data() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_clear_my_pengu_fisher_data() TO authenticated;
