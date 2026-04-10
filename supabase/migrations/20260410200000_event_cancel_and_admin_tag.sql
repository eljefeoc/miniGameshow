-- Competition cancel (soft) + optional admin-only tag for sidebar context.
-- canceled_at: when set, event is not competable; uncancel not supported in product.
-- admin_tag: optional label (e.g. "Noodling", "Beta") — display/admin only.

ALTER TABLE public.events
  ADD COLUMN IF NOT EXISTS canceled_at timestamptz,
  ADD COLUMN IF NOT EXISTS admin_tag text;

COMMENT ON COLUMN public.events.canceled_at IS 'When set, scoring is closed and runs are rejected; irreversible in admin UI.';
COMMENT ON COLUMN public.events.admin_tag IS 'Optional admin-only label for past-event lists (e.g. dev vs beta).';

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
  IF EXISTS (
    SELECT 1 FROM public.events e
    WHERE e.id = NEW.event_id AND e.canceled_at IS NOT NULL
  ) THEN
    RAISE EXCEPTION 'competition event was canceled';
  END IF;

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
