-- Admin: delete weeks, profile flags RPC, clear competition data, ban enforcement on runs

CREATE POLICY "weeks_delete_admin"
  ON public.weeks FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );

CREATE OR REPLACE FUNCTION public.before_run_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_used smallint;
  v_next smallint;
  v_banned boolean;
BEGIN
  IF auth.uid() IS NOT NULL AND NEW.user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'user_id must match authenticated user';
  END IF;

  SELECT COALESCE(is_banned, false) INTO v_banned
  FROM public.profiles
  WHERE id = NEW.user_id;

  IF v_banned THEN
    RAISE EXCEPTION 'account is banned from competition';
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

CREATE OR REPLACE FUNCTION public.admin_set_profile_flags(
  target_user_id uuid,
  p_is_admin boolean,
  p_is_banned boolean
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true
  ) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  IF target_user_id = auth.uid() AND p_is_admin = false THEN
    RAISE EXCEPTION 'cannot remove your own admin flag';
  END IF;

  UPDATE public.profiles
  SET is_admin = p_is_admin,
      is_banned = p_is_banned
  WHERE id = target_user_id;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'profile not found';
  END IF;
END;
$$;

CREATE OR REPLACE FUNCTION public.admin_clear_user_competition_data(target_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  affected_weeks uuid[];
  w uuid;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM public.profiles WHERE id = auth.uid() AND is_admin = true
  ) THEN
    RAISE EXCEPTION 'not authorized';
  END IF;

  SELECT array_agg(DISTINCT week_id) INTO affected_weeks
  FROM (
    SELECT week_id FROM public.leaderboard WHERE user_id = target_user_id
    UNION
    SELECT week_id FROM public.runs WHERE user_id = target_user_id
  ) s;

  IF affected_weeks IS NULL THEN
    affected_weeks := ARRAY[]::uuid[];
  END IF;

  DELETE FROM public.leaderboard WHERE user_id = target_user_id;
  DELETE FROM public.runs WHERE user_id = target_user_id;
  DELETE FROM public.daily_attempts WHERE user_id = target_user_id;

  FOREACH w IN ARRAY affected_weeks LOOP
    PERFORM public.refresh_leaderboard_ranks(w);
  END LOOP;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_set_profile_flags(uuid, boolean, boolean) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.admin_clear_user_competition_data(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.admin_set_profile_flags(uuid, boolean, boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.admin_clear_user_competition_data(uuid) TO authenticated;
