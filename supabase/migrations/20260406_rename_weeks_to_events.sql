-- MiniGameshow — Rename weeks → events
-- Apply via Supabase SQL Editor (paste and Run).
-- Apply code changes (penguin-game.html, admin.html, schema.sql) in the same sitting.
-- -------------------------------------------------------------------------

-- ── 1. Rename the table ──────────────────────────────────────────────────
ALTER TABLE public.weeks RENAME TO events;

-- ── 2. Rename columns ────────────────────────────────────────────────────
ALTER TABLE public.events RENAME COLUMN week_code TO event_code;
ALTER TABLE public.runs   RENAME COLUMN week_id   TO event_id;
ALTER TABLE public.leaderboard RENAME COLUMN week_id TO event_id;

-- ── 3. Rename indexes ─────────────────────────────────────────────────────
ALTER INDEX IF EXISTS weeks_code_idx         RENAME TO events_code_idx;
ALTER INDEX IF EXISTS weeks_window_idx       RENAME TO events_window_idx;
ALTER INDEX IF EXISTS runs_user_week_idx     RENAME TO runs_user_event_idx;
ALTER INDEX IF EXISTS runs_week_score_idx    RENAME TO runs_event_score_idx;
ALTER INDEX IF EXISTS leaderboard_week_rank_idx  RENAME TO leaderboard_event_rank_idx;
ALTER INDEX IF EXISTS leaderboard_week_score_idx RENAME TO leaderboard_event_score_idx;

-- ── 4. Drop old RLS policies, recreate with new names ────────────────────
-- (Policy names cannot be renamed — must drop and recreate.)
DROP POLICY IF EXISTS "weeks_select_all"    ON public.events;
DROP POLICY IF EXISTS "weeks_insert_admin"  ON public.events;
DROP POLICY IF EXISTS "weeks_update_admin"  ON public.events;

CREATE POLICY "events_select_all"
  ON public.events FOR SELECT
  USING (true);

CREATE POLICY "events_insert_admin"
  ON public.events FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE POLICY "events_update_admin"
  ON public.events FOR UPDATE
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

-- ── 5. Rewrite trigger functions that reference week_id by name ───────────
-- PostgreSQL does NOT auto-update column names inside function bodies on rename.
-- refresh_leaderboard_ranks must be DROPped first because its parameter is being
-- renamed (p_week_id → p_event_id); CREATE OR REPLACE cannot change param names.
-- after_run_insert / after_run_delete have no param name change so CREATE OR REPLACE
-- works for those — and they must NOT be dropped (triggers depend on them).

DROP FUNCTION IF EXISTS public.refresh_leaderboard_ranks(uuid);

CREATE OR REPLACE FUNCTION public.refresh_leaderboard_ranks(p_event_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  WITH ranked AS (
    SELECT
      user_id,
      event_id,
      row_number() OVER (ORDER BY best_score DESC, updated_at ASC) AS rnk
    FROM public.leaderboard
    WHERE event_id = p_event_id
  )
  UPDATE public.leaderboard l
  SET rank = ranked.rnk,
      updated_at = now()
  FROM ranked
  WHERE l.user_id = ranked.user_id
    AND l.event_id = ranked.event_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.after_run_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_old_best bigint;
BEGIN
  SELECT best_score INTO v_old_best
  FROM public.leaderboard
  WHERE user_id = NEW.user_id AND event_id = NEW.event_id;

  IF v_old_best IS NULL OR NEW.score > v_old_best THEN
    INSERT INTO public.leaderboard (user_id, event_id, best_score, best_run_id, rank)
    VALUES (NEW.user_id, NEW.event_id, NEW.score, NEW.id, NULL)
    ON CONFLICT (user_id, event_id) DO UPDATE
      SET best_score = EXCLUDED.best_score,
          best_run_id = EXCLUDED.best_run_id,
          updated_at = now()
      WHERE EXCLUDED.best_score > public.leaderboard.best_score;
  END IF;

  PERFORM public.refresh_leaderboard_ranks(NEW.event_id);

  INSERT INTO public.content_events (event_type, metadata)
  VALUES (
    'run_submitted',
    jsonb_build_object(
      'run_id', NEW.id,
      'user_id', NEW.user_id,
      'event_id', NEW.event_id,
      'score', NEW.score,
      'attempt_num', NEW.attempt_num,
      'day_seed', NEW.day_seed
    )
  );

  IF v_old_best IS NULL OR NEW.score > COALESCE(v_old_best, -1) THEN
    INSERT INTO public.content_events (event_type, metadata)
    VALUES (
      'new_high_score',
      jsonb_build_object(
        'run_id', NEW.id,
        'user_id', NEW.user_id,
        'event_id', NEW.event_id,
        'score', NEW.score,
        'previous_best', v_old_best
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

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
      AND event_id = OLD.event_id
      AND best_run_id = OLD.id
  ) THEN
    SELECT r.id, r.score INTO v_best_id, v_best_score
    FROM public.runs r
    WHERE r.user_id = OLD.user_id AND r.event_id = OLD.event_id
    ORDER BY r.score DESC, r.created_at ASC
    LIMIT 1;

    IF v_best_id IS NULL THEN
      DELETE FROM public.leaderboard
      WHERE user_id = OLD.user_id AND event_id = OLD.event_id;
    ELSE
      UPDATE public.leaderboard
      SET best_score = v_best_score,
          best_run_id = v_best_id,
          updated_at = now()
      WHERE user_id = OLD.user_id AND event_id = OLD.event_id;
    END IF;

    PERFORM public.refresh_leaderboard_ranks(OLD.event_id);
  END IF;

  RETURN OLD;
END;
$$;
