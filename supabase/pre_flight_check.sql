-- Run these in Supabase SQL Editor BEFORE applying schema.sql if the DB might already have objects.
-- Interpretation: if a query returns rows, you have a potential naming conflict — see README.

-- 1) Tables our schema creates (public schema)
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_name IN (
    'games', 'profiles', 'events', 'runs', 'leaderboard',
    'daily_attempts', 'content_events'
  )
ORDER BY table_name;

-- 2) Functions we define (same names = conflict if different signature/behavior)
SELECT routine_name
FROM information_schema.routines
WHERE routine_schema = 'public'
  AND routine_name IN (
    'handle_new_user', 'set_updated_at', 'refresh_leaderboard_ranks',
    'after_run_insert', 'before_run_insert'
  )
ORDER BY routine_name;

-- 3) Triggers on auth.users (we add on_auth_user_created)
SELECT trigger_name, event_manipulation, action_timing
FROM information_schema.triggers
WHERE event_object_schema = 'auth'
  AND event_object_table = 'users'
ORDER BY trigger_name;
