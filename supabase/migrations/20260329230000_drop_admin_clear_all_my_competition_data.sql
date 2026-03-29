-- Remove destructive admin stress-test RPC and its content_events DELETE policy (UI removed from admin.html).

DROP FUNCTION IF EXISTS public.admin_clear_all_my_competition_data();

DROP POLICY IF EXISTS "content_events_delete_own_meta" ON public.content_events;
