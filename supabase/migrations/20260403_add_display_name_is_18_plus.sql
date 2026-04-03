-- Phase 2: Add display_name and is_18_plus to profiles for AUTH-04 and AUTH-05
ALTER TABLE public.profiles
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS is_18_plus boolean NOT NULL DEFAULT false;

-- Update trigger to capture display_name and is_18_plus from signup metadata
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
