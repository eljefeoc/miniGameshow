-- Allow admins to SELECT all runs (not just their own).
-- The existing runs_select_own policy already covers the user_id = auth.uid() case;
-- Postgres OR's multiple policies together, so admins get both.
CREATE POLICY "runs_select_admin"
  ON public.runs FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND is_admin = true
    )
  );
