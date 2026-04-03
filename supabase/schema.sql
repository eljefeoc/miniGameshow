-- MiniGameshow — Supabase schema (GAME_BIBLE §8)
--
-- Apply once per project:
--   Supabase Dashboard → SQL Editor → paste → Run
-- Or with CLI: supabase link && supabase db push (uses supabase/migrations/)
--
-- Keep in sync with: supabase/migrations/20250327120000_initial_schema.sql

-- -----------------------------------------------------------------------------
-- Extensions
-- -----------------------------------------------------------------------------
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- -----------------------------------------------------------------------------
-- Core reference data
-- -----------------------------------------------------------------------------
CREATE TABLE public.games (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug text NOT NULL UNIQUE,
  name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- -----------------------------------------------------------------------------
-- Profiles (extends auth.users — no email here; use auth.users / JWT in app)
-- -----------------------------------------------------------------------------
CREATE TABLE public.profiles (
  id uuid PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  username text UNIQUE,
  display_name text,
  is_18_plus boolean NOT NULL DEFAULT false,
  phone text,
  phone_verified boolean NOT NULL DEFAULT false,
  country text,
  is_banned boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX profiles_username_lower_idx ON public.profiles (lower(username));

-- -----------------------------------------------------------------------------
-- Weeks (weekly competition window)
-- -----------------------------------------------------------------------------
CREATE TABLE public.weeks (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  week_code text NOT NULL UNIQUE,
  game_id uuid NOT NULL REFERENCES public.games (id) ON DELETE RESTRICT,
  seed bigint,
  starts_at timestamptz NOT NULL,
  ends_at timestamptz NOT NULL,
  prize_title text,
  sponsor_name text,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT weeks_time_order CHECK (ends_at > starts_at)
);

CREATE INDEX weeks_code_idx ON public.weeks (week_code);
CREATE INDEX weeks_window_idx ON public.weeks (starts_at, ends_at);

-- -----------------------------------------------------------------------------
-- Runs (score submissions; replay_payload holds anti-cheat / validation data)
-- -----------------------------------------------------------------------------
CREATE TABLE public.runs (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  week_id uuid NOT NULL REFERENCES public.weeks (id) ON DELETE CASCADE,
  score bigint NOT NULL CHECK (score >= 0),
  attempt_num smallint NOT NULL CHECK (attempt_num >= 1 AND attempt_num <= 5),
  duration_ms integer NOT NULL CHECK (duration_ms >= 0),
  -- Same value as GAME_BIBLE score payload `seed` (date-derived daily PRNG seed)
  day_seed integer NOT NULL,
  input_count integer NOT NULL DEFAULT 0 CHECK (input_count >= 0),
  input_log jsonb,
  frame_checkpoints jsonb,
  game_version text NOT NULL DEFAULT '0.0.0',
  replay_payload jsonb,
  is_validated boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX runs_user_week_idx ON public.runs (user_id, week_id);
CREATE INDEX runs_week_score_idx ON public.runs (week_id, score DESC);
CREATE INDEX runs_day_seed_idx ON public.runs (user_id, day_seed);

-- -----------------------------------------------------------------------------
-- Leaderboard (one row per user per week — best run)
-- -----------------------------------------------------------------------------
CREATE TABLE public.leaderboard (
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  week_id uuid NOT NULL REFERENCES public.weeks (id) ON DELETE CASCADE,
  best_score bigint NOT NULL CHECK (best_score >= 0),
  best_run_id uuid NOT NULL REFERENCES public.runs (id) ON DELETE RESTRICT,
  rank integer,
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, week_id)
);

CREATE INDEX leaderboard_week_rank_idx ON public.leaderboard (week_id, rank);
CREATE INDEX leaderboard_week_score_idx ON public.leaderboard (week_id, best_score DESC);

-- -----------------------------------------------------------------------------
-- Daily attempts (5 per calendar day per daily seed)
-- -----------------------------------------------------------------------------
CREATE TABLE public.daily_attempts (
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  day_seed integer NOT NULL,
  attempts_used smallint NOT NULL DEFAULT 0 CHECK (attempts_used >= 0 AND attempts_used <= 5),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, day_seed)
);

-- -----------------------------------------------------------------------------
-- Content / social pipeline (DB triggers or Edge → jobs)
-- -----------------------------------------------------------------------------
CREATE TABLE public.content_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  event_type text NOT NULL,
  metadata jsonb NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX content_events_type_created_idx ON public.content_events (event_type, created_at DESC);

-- -----------------------------------------------------------------------------
-- Timestamps: profiles.updated_at
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$;

CREATE TRIGGER profiles_set_updated_at
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.set_updated_at();

-- -----------------------------------------------------------------------------
-- Auth: create profile row when a user signs up
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, display_name, is_18_plus)
  VALUES (
    NEW.id,
    NULLIF(trim(NEW.raw_user_meta_data->>'display_name'), ''),
    COALESCE((NEW.raw_user_meta_data->>'is_18_plus')::boolean, false)
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

-- -----------------------------------------------------------------------------
-- Leaderboard: recompute ranks for a week (dense by score order)
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.refresh_leaderboard_ranks(p_week_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  WITH ranked AS (
    SELECT
      user_id,
      week_id,
      row_number() OVER (ORDER BY best_score DESC, updated_at ASC) AS rnk
    FROM public.leaderboard
    WHERE week_id = p_week_id
  )
  UPDATE public.leaderboard l
  SET rank = ranked.rnk,
      updated_at = now()
  FROM ranked
  WHERE l.user_id = ranked.user_id
    AND l.week_id = ranked.week_id;
END;
$$;

-- -----------------------------------------------------------------------------
-- Runs: enforce max 5 attempts per user per day_seed; update leaderboard
-- -----------------------------------------------------------------------------
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
  WHERE user_id = NEW.user_id AND week_id = NEW.week_id;

  IF v_old_best IS NULL OR NEW.score > v_old_best THEN
    INSERT INTO public.leaderboard (user_id, week_id, best_score, best_run_id, rank)
    VALUES (NEW.user_id, NEW.week_id, NEW.score, NEW.id, NULL)
    ON CONFLICT (user_id, week_id) DO UPDATE
      SET best_score = EXCLUDED.best_score,
          best_run_id = EXCLUDED.best_run_id,
          updated_at = now()
      WHERE EXCLUDED.best_score > public.leaderboard.best_score;
  END IF;

  PERFORM public.refresh_leaderboard_ranks(NEW.week_id);

  INSERT INTO public.content_events (event_type, metadata)
  VALUES (
    'run_submitted',
    jsonb_build_object(
      'run_id', NEW.id,
      'user_id', NEW.user_id,
      'week_id', NEW.week_id,
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
        'week_id', NEW.week_id,
        'score', NEW.score,
        'previous_best', v_old_best
      )
    );
  END IF;

  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION public.before_run_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_used smallint;
  v_next smallint;
BEGIN
  -- Direct client inserts: JWT must match. Service role (Edge) bypasses RLS; trust server-side validation.
  IF auth.uid() IS NOT NULL AND NEW.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'user_id must match authenticated user';
  END IF;

  INSERT INTO public.daily_attempts (user_id, day_seed, attempts_used)
  VALUES (NEW.user_id, NEW.day_seed, 0)
  ON CONFLICT (user_id, day_seed) DO NOTHING;

  SELECT attempts_used INTO v_used
  FROM public.daily_attempts
  WHERE user_id = NEW.user_id AND day_seed = NEW.day_seed
  FOR UPDATE;

  IF v_used >= 5 THEN
    RAISE EXCEPTION 'daily attempt limit (5) reached for this day';
  END IF;

  UPDATE public.daily_attempts
  SET attempts_used = attempts_used + 1,
      updated_at = now()
  WHERE user_id = NEW.user_id AND day_seed = NEW.day_seed
  RETURNING attempts_used INTO v_next;

  NEW.attempt_num := v_next;

  RETURN NEW;
END;
$$;

CREATE TRIGGER runs_before_insert
  BEFORE INSERT ON public.runs
  FOR EACH ROW
  EXECUTE FUNCTION public.before_run_insert();

CREATE TRIGGER runs_after_insert
  AFTER INSERT ON public.runs
  FOR EACH ROW
  EXECUTE FUNCTION public.after_run_insert();

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

CREATE TRIGGER runs_after_delete
  AFTER DELETE ON public.runs
  FOR EACH ROW
  EXECUTE FUNCTION public.after_run_delete();

-- -----------------------------------------------------------------------------
-- Row Level Security
-- -----------------------------------------------------------------------------
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.games ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weeks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.runs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.leaderboard ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_attempts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.content_events ENABLE ROW LEVEL SECURITY;

-- Profiles: users manage self; anyone can read minimal fields for leaderboard UX
CREATE POLICY "profiles_select_public"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "profiles_update_own"
  ON public.profiles FOR UPDATE
  TO authenticated
  USING (id = auth.uid())
  WITH CHECK (id = auth.uid());

-- Games & weeks: public read
CREATE POLICY "games_select_all"
  ON public.games FOR SELECT
  USING (true);

CREATE POLICY "weeks_select_all"
  ON public.weeks FOR SELECT
  USING (true);

-- Runs: insert own; read own (leaderboard uses leaderboard table)
CREATE POLICY "runs_insert_own"
  ON public.runs FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "runs_select_own"
  ON public.runs FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "runs_delete_own"
  ON public.runs FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Leaderboard: public read
CREATE POLICY "leaderboard_select_all"
  ON public.leaderboard FOR SELECT
  USING (true);

CREATE POLICY "leaderboard_delete_own"
  ON public.leaderboard FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- Daily attempts: own rows only
CREATE POLICY "daily_attempts_select_own"
  ON public.daily_attempts FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "daily_attempts_delete_own"
  ON public.daily_attempts FOR DELETE
  TO authenticated
  USING (user_id = auth.uid());

-- content_events: no direct client access (service role / triggers bypass RLS)

-- -----------------------------------------------------------------------------
-- Seed: default game (idempotent)
-- -----------------------------------------------------------------------------
INSERT INTO public.games (slug, name)
VALUES ('pengu-fisher', 'Pengu Fisher')
ON CONFLICT (slug) DO NOTHING;

-- Example: create the current competition week (run manually after deploy; adjust ISO week + window)
-- INSERT INTO public.weeks (week_code, game_id, seed, starts_at, ends_at, prize_title, sponsor_name)
-- SELECT
--   '2026-W13',
--   id,
--   20260323,
--   timestamptz '2026-03-23 00:00:00+00',
--   timestamptz '2026-03-28 23:59:59+00',
--   'Prize title TBD',
--   NULL
-- FROM public.games WHERE slug = 'pengu-fisher';
