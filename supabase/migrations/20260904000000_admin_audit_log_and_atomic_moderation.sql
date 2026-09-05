-- Admin accountability + atomic moderation.
--
-- 1. public.admin_audit_log — append-only record of admin decisions
--    (approve / verify / hide / report / commission). Written only through
--    public.log_admin_action; UPDATE and DELETE are blocked by trigger.
-- 2. public.hide_review_and_close_report — one transaction instead of the
--    dashboard's two sequential writes, which could leave a hidden review
--    attached to a still-open report.
--
-- Safe to apply on live Dahr LY: CREATE ... IF NOT EXISTS / CREATE OR REPLACE
-- / DROP ... IF EXISTS. Does not touch bookings, reviews data, or the
-- vendor-photos bucket.

-- ---------------------------------------------------------------------------
-- 1. Audit log table
-- ---------------------------------------------------------------------------
-- actor_id is deliberately not a foreign key: the log must outlive an account
-- deletion (guideline 5.1.1(v) cascades profiles), and an ON DELETE action
-- would mean writing to an append-only table.
CREATE TABLE IF NOT EXISTS public.admin_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_id UUID NOT NULL,
  action TEXT NOT NULL,
  target_type TEXT NOT NULL,
  target_id UUID,
  detail JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.admin_audit_log IS
  'Append-only admin action log. Insert only via public.log_admin_action; UPDATE/DELETE rejected by trigger.';

CREATE INDEX IF NOT EXISTS idx_admin_audit_log_created_at
  ON public.admin_audit_log (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_admin_audit_log_target
  ON public.admin_audit_log (target_type, target_id);

ALTER TABLE public.admin_audit_log ENABLE ROW LEVEL SECURITY;

-- Admins read the log. There is no INSERT/UPDATE/DELETE policy on purpose:
-- the only writer is the SECURITY DEFINER helper below.
DROP POLICY IF EXISTS admin_audit_log_select_admin ON public.admin_audit_log;
CREATE POLICY admin_audit_log_select_admin ON public.admin_audit_log
  FOR SELECT TO authenticated
  USING (public.is_admin());

REVOKE ALL ON public.admin_audit_log FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.admin_audit_log TO authenticated;

-- Append-only, including for service_role and the SECURITY DEFINER helper.
CREATE OR REPLACE FUNCTION public.reject_admin_audit_log_rewrite()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  RAISE EXCEPTION 'admin_audit_log is append-only';
END;
$$;

REVOKE ALL ON FUNCTION public.reject_admin_audit_log_rewrite() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS admin_audit_log_append_only ON public.admin_audit_log;
CREATE TRIGGER admin_audit_log_append_only
  BEFORE UPDATE OR DELETE ON public.admin_audit_log
  FOR EACH ROW
  EXECUTE FUNCTION public.reject_admin_audit_log_rewrite();

-- ---------------------------------------------------------------------------
-- 2. The only writer
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.log_admin_action(
  p_action TEXT,
  p_target_type TEXT,
  p_target_id UUID DEFAULT NULL,
  p_detail JSONB DEFAULT '{}'::jsonb
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  actor UUID;
  new_id UUID;
BEGIN
  actor := auth.uid();
  IF actor IS NULL OR NOT public.is_admin() THEN
    RAISE EXCEPTION 'only admin may write the audit log';
  END IF;

  IF p_action IS NULL OR p_action NOT IN (
    'vendor_approved',
    'vendor_revoked',
    'vendor_verified',
    'vendor_unverified',
    'review_hidden',
    'report_dismissed',
    'report_actioned',
    'commission_paid',
    'commission_waived'
  ) THEN
    RAISE EXCEPTION 'unknown_audit_action';
  END IF;

  IF p_target_type IS NULL OR p_target_type NOT IN (
    'vendor',
    'review',
    'report',
    'booking'
  ) THEN
    RAISE EXCEPTION 'unknown_audit_target';
  END IF;

  INSERT INTO public.admin_audit_log (
    actor_id, action, target_type, target_id, detail
  )
  VALUES (
    actor,
    p_action,
    p_target_type,
    p_target_id,
    COALESCE(p_detail, '{}'::jsonb)
  )
  RETURNING id INTO new_id;

  RETURN new_id;
END;
$$;

COMMENT ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB) IS
  'Appends one admin decision to admin_audit_log as auth.uid(). Admin only; action and target_type are allowlisted.';

REVOKE ALL ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.log_admin_action(TEXT, TEXT, UUID, JSONB)
  TO authenticated;

-- ---------------------------------------------------------------------------
-- 3. Hide a review and close its report in one transaction
-- ---------------------------------------------------------------------------
-- SECURITY INVOKER: the reviews / reports admin policies and the
-- reviews_protect_moderation trigger still apply. The explicit is_admin()
-- check only turns a silent no-op into a clear error.
CREATE OR REPLACE FUNCTION public.hide_review_and_close_report(
  p_review_id UUID,
  p_report_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  hidden_id UUID;
  closed_id UUID;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'only admin may hide a review';
  END IF;

  UPDATE public.reviews
  SET is_hidden = true
  WHERE id = p_review_id
  RETURNING id INTO hidden_id;

  IF hidden_id IS NULL THEN
    RAISE EXCEPTION 'review_not_found';
  END IF;

  PERFORM public.log_admin_action(
    'review_hidden',
    'review',
    hidden_id,
    jsonb_build_object('report_id', p_report_id)
  );

  IF p_report_id IS NOT NULL THEN
    UPDATE public.reports
    SET status = 'actioned'::public.report_status
    WHERE id = p_report_id
    RETURNING id INTO closed_id;

    IF closed_id IS NULL THEN
      RAISE EXCEPTION 'report_not_found';
    END IF;

    PERFORM public.log_admin_action(
      'report_actioned',
      'report',
      closed_id,
      jsonb_build_object('review_id', hidden_id)
    );
  END IF;

  RETURN hidden_id;
END;
$$;

COMMENT ON FUNCTION public.hide_review_and_close_report(UUID, UUID) IS
  'Admin moderation: hides a review and marks its report actioned in one transaction, logging both.';

REVOKE ALL ON FUNCTION public.hide_review_and_close_report(UUID, UUID)
  FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.hide_review_and_close_report(UUID, UUID)
  TO authenticated;
