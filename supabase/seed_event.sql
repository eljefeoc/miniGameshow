-- Insert one competition event for Pengu Fisher covering the current hour in UTC.
-- Safe to re-run: ON CONFLICT (event_code) DO NOTHING.
-- Run in Supabase SQL Editor after `games` has `pengu-fisher`.
--
-- ► Edit event_code, prize_title, prize_description, show_at, starts_at,
--   and ends_at before running.
--   show_at is the live show start time (use UTC, e.g. 03:00 UTC = 7pm PT).
--   starts_at / ends_at can be any duration — hourly, daily, multi-day, or weekly.

INSERT INTO public.events (
  event_code, game_id, seed,
  starts_at, ends_at,
  show_at, show_url,
  prize_title, prize_description, sponsor_name
)
SELECT
  -- event_code: change to any unique identifier, e.g. '2026-E01' or '2026-04-06-test'
  to_char(now() AT TIME ZONE 'utc', 'YYYY-MM-DD-HH24'),
  g.id,
  (to_char((now() AT TIME ZONE 'utc')::date, 'YYYYMMDD'))::bigint,
  -- Scoring window: now → 1 hour from now (adjust as needed)
  now(),
  now() + interval '1 hour',
  -- Live show: 15 minutes after scoring closes (set to NULL if no live show)
  now() + interval '1 hour 15 minutes',
  NULL,                           -- show_url (set via admin panel)
  'Test event prize TBD',         -- ◄ replace with real prize title
  NULL,                           -- ◄ optional longer description
  NULL                            -- ◄ optional sponsor name
FROM public.games g
WHERE g.slug = 'pengu-fisher'
ON CONFLICT (event_code) DO NOTHING
RETURNING id, event_code, starts_at, ends_at, show_at, prize_title;
