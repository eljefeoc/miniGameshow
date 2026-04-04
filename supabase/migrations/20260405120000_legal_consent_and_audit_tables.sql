-- Legal: consent audit trail, prize tracking, disqualification log
-- See LEGAL_IMPLEMENTATION_BRIEF.md — attorney review required before production use.

-- -----------------------------------------------------------------------------
-- user_legal_consent — every consent event (TOS, competition rules, age declaration)
-- -----------------------------------------------------------------------------
CREATE TABLE public.user_legal_consent (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users (id) ON DELETE CASCADE,
  consent_type text NOT NULL
    CHECK (consent_type IN ('tos_general', 'competition_rules', 'age_declaration')),
  document_version text NOT NULL,
  accepted_at timestamptz NOT NULL DEFAULT now(),
  ip_address text,
  user_agent text
);

CREATE INDEX user_legal_consent_user_idx ON public.user_legal_consent (user_id);
CREATE INDEX user_legal_consent_type_idx ON public.user_legal_consent (user_id, consent_type);

ALTER TABLE public.user_legal_consent ENABLE ROW LEVEL SECURITY;

CREATE POLICY "user_legal_consent_insert_own"
  ON public.user_legal_consent FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "user_legal_consent_select_own"
  ON public.user_legal_consent FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "user_legal_consent_select_admin"
  ON public.user_legal_consent FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

-- -----------------------------------------------------------------------------
-- prize_awards — cumulative prize value / tax-year tracking (backend checklist)
-- -----------------------------------------------------------------------------
CREATE TABLE public.prize_awards (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  week_id uuid REFERENCES public.weeks (id) ON DELETE SET NULL,
  description text,
  value_usd numeric(12, 2) NOT NULL DEFAULT 0,
  awarded_at timestamptz NOT NULL DEFAULT now(),
  tax_year integer NOT NULL GENERATED ALWAYS AS (EXTRACT(YEAR FROM awarded_at AT TIME ZONE 'UTC')::integer) STORED,
  notes text
);

CREATE INDEX prize_awards_user_tax_year_idx ON public.prize_awards (user_id, tax_year);

ALTER TABLE public.prize_awards ENABLE ROW LEVEL SECURITY;

-- No player-facing SELECT by default; admins only until product defines winner portal.
CREATE POLICY "prize_awards_select_admin"
  ON public.prize_awards FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

CREATE POLICY "prize_awards_insert_admin"
  ON public.prize_awards FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

-- -----------------------------------------------------------------------------
-- disqualifications — human-reviewed; references run that triggered review
-- -----------------------------------------------------------------------------
CREATE TABLE public.disqualifications (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  run_id uuid NOT NULL REFERENCES public.runs (id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reason_code text NOT NULL,
  notes text,
  created_by uuid REFERENCES auth.users (id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX disqualifications_run_idx ON public.disqualifications (run_id);
CREATE INDEX disqualifications_user_idx ON public.disqualifications (user_id);

ALTER TABLE public.disqualifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "disqualifications_select_admin"
  ON public.disqualifications FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );

CREATE POLICY "disqualifications_insert_admin"
  ON public.disqualifications FOR INSERT
  TO authenticated
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.profiles p
      WHERE p.id = auth.uid() AND p.is_admin = true
    )
  );
