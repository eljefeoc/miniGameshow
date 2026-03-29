-- Insert one competition week for Pengu Fisher (current ISO week in UTC).
-- Safe to re-run: ON CONFLICT (week_code) DO NOTHING.
-- Run in Supabase SQL Editor after `games` has `pengu-fisher`.

INSERT INTO public.weeks (week_code, game_id, seed, starts_at, ends_at, prize_title, sponsor_name)
SELECT
  to_char(date_trunc('week', timezone('utc', now())), 'IYYY') || '-W' || to_char(date_trunc('week', timezone('utc', now())), 'IW'),
  g.id,
  (to_char((timezone('utc', now()))::date, 'YYYYMMDD'))::bigint,
  date_trunc('week', timezone('utc', now())),
  date_trunc('week', timezone('utc', now())) + interval '6 days 23 hours 59 minutes 59 seconds',
  'Weekly prize TBD',
  NULL
FROM public.games g
WHERE g.slug = 'pengu-fisher'
ON CONFLICT (week_code) DO NOTHING
RETURNING id, week_code, starts_at, ends_at;
