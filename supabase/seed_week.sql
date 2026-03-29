-- Insert one competition week for Pengu Fisher (current ISO week in UTC).
-- Safe to re-run: ON CONFLICT (week_code) DO NOTHING.
-- Run in Supabase SQL Editor after `games` has `pengu-fisher`.
--
-- ► Edit prize_title, prize_description, and show_at before running.
--   show_at is the Sunday live show start time (use UTC, e.g. 03:00 UTC = 7pm PT).

INSERT INTO public.weeks (
  week_code, game_id, seed,
  starts_at, ends_at,
  show_at, show_url,
  prize_title, prize_description, sponsor_name
)
SELECT
  to_char(date_trunc('week', timezone('utc', now())), 'IYYY') || '-W'
    || to_char(date_trunc('week', timezone('utc', now())), 'IW'),
  g.id,
  (to_char((timezone('utc', now()))::date, 'YYYYMMDD'))::bigint,
  -- Scoring window: Mon 00:00 UTC → Sat 23:59:59 UTC
  date_trunc('week', timezone('utc', now())),
  date_trunc('week', timezone('utc', now())) + interval '5 days 23 hours 59 minutes 59 seconds',
  -- Live show: Sunday of this ISO week at 03:00 UTC (= 7pm PT / 10pm ET)
  date_trunc('week', timezone('utc', now())) + interval '6 days 3 hours',
  NULL,                           -- show_url (set via admin panel)
  'Weekly prize TBD',             -- ◄ replace with real prize title
  NULL,                           -- ◄ optional longer description
  NULL                            -- ◄ optional sponsor name
FROM public.games g
WHERE g.slug = 'pengu-fisher'
ON CONFLICT (week_code) DO NOTHING
RETURNING id, week_code, starts_at, ends_at, show_at, prize_title;
