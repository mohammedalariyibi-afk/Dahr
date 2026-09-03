-- Booking commission: 10% of the vendor quote, paid by the vendor to Dahr
-- offline (WhatsApp / cash). Couples are not charged in-app. No payment
-- processor — admin marks commission paid or waived after collection.

CREATE TYPE public.commission_status AS ENUM ('unpaid', 'paid', 'waived');

ALTER TABLE public.booking_requests
  ADD COLUMN quoted_amount_lyd NUMERIC(12, 2),
  ADD COLUMN commission_rate NUMERIC(5, 4) NOT NULL DEFAULT 0.1000,
  ADD COLUMN commission_amount_lyd NUMERIC(12, 2),
  ADD COLUMN commission_status public.commission_status,
  ADD COLUMN commission_paid_at TIMESTAMPTZ;

ALTER TABLE public.booking_requests
  ADD CONSTRAINT booking_quoted_amount_positive
    CHECK (quoted_amount_lyd IS NULL OR quoted_amount_lyd > 0),
  ADD CONSTRAINT booking_commission_rate_range
    CHECK (commission_rate > 0 AND commission_rate <= 1),
  ADD CONSTRAINT booking_commission_matches_quote
    CHECK (
      quoted_amount_lyd IS NULL
      OR commission_amount_lyd = ROUND(quoted_amount_lyd * commission_rate, 2)
    ),
  ADD CONSTRAINT booking_quote_status_consistency
    CHECK (
      (
        quoted_amount_lyd IS NULL
        AND commission_amount_lyd IS NULL
        AND commission_status IS NULL
      )
      OR (
        quoted_amount_lyd IS NOT NULL
        AND commission_amount_lyd IS NOT NULL
        AND commission_status IS NOT NULL
      )
    ),
  ADD CONSTRAINT booking_accepted_requires_quote
    CHECK (
      status <> 'accepted'::public.booking_status
      OR quoted_amount_lyd IS NOT NULL
    );

COMMENT ON COLUMN public.booking_requests.quoted_amount_lyd IS
  'Vendor quote in LYD, required when accepting. Couple pays the vendor off-platform.';
COMMENT ON COLUMN public.booking_requests.commission_rate IS
  'Dahr commission rate recorded on the booking (default 10%).';
COMMENT ON COLUMN public.booking_requests.commission_amount_lyd IS
  'ROUND(quoted_amount_lyd * commission_rate, 2). Paid by the vendor to Dahr, not the couple.';
COMMENT ON COLUMN public.booking_requests.commission_status IS
  'unpaid when a quote exists; admin sets paid or waived after offline collection. Null until accepted.';
COMMENT ON COLUMN public.booking_requests.commission_paid_at IS
  'When an admin marked the vendor commission as paid.';

CREATE INDEX idx_booking_requests_commission_status
  ON public.booking_requests (commission_status)
  WHERE quoted_amount_lyd IS NOT NULL;

-- Vendors (and admins) may update bookings. Consumers can no longer UPDATE
-- rows — they only INSERT requests. Commission paid/waived is enforced in
-- the trigger below even if a client sends those fields.
DROP POLICY IF EXISTS bookings_update_parties ON public.booking_requests;
CREATE POLICY bookings_update_vendor_or_admin ON public.booking_requests
  FOR UPDATE USING (
    public.owns_vendor(vendor_id) OR public.is_admin()
  )
  WITH CHECK (
    public.owns_vendor(vendor_id) OR public.is_admin()
  );

CREATE OR REPLACE FUNCTION public.protect_booking_commission()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  is_service BOOLEAN;
  admin_user BOOLEAN;
  vendor_owner BOOLEAN;
BEGIN
  is_service := auth.uid() IS NULL;
  admin_user := (NOT is_service) AND public.is_admin();
  vendor_owner := (NOT is_service) AND public.owns_vendor(NEW.vendor_id);

  IF NEW.commission_rate IS NULL THEN
    NEW.commission_rate := 0.1000;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF is_service OR admin_user THEN
      IF NEW.quoted_amount_lyd IS NOT NULL THEN
        NEW.commission_amount_lyd :=
          ROUND(NEW.quoted_amount_lyd * NEW.commission_rate, 2);
        IF NEW.commission_status IS NULL THEN
          NEW.commission_status := 'unpaid';
        END IF;
        IF NEW.commission_status = 'paid' THEN
          NEW.commission_paid_at := COALESCE(NEW.commission_paid_at, now());
        ELSE
          NEW.commission_paid_at := NULL;
        END IF;
      ELSE
        NEW.commission_amount_lyd := NULL;
        NEW.commission_status := NULL;
        NEW.commission_paid_at := NULL;
      END IF;
      RETURN NEW;
    END IF;

    -- Couples creating a request: never attach money on insert.
    NEW.quoted_amount_lyd := NULL;
    NEW.commission_amount_lyd := NULL;
    NEW.commission_status := NULL;
    NEW.commission_paid_at := NULL;
    NEW.commission_rate := 0.1000;
    IF NEW.status = 'accepted' THEN
      RAISE EXCEPTION 'cannot insert an accepted booking; vendor must accept with a quote';
    END IF;
    RETURN NEW;
  END IF;

  -- UPDATE
  IF is_service THEN
    IF NEW.quoted_amount_lyd IS NOT NULL THEN
      NEW.commission_amount_lyd :=
        ROUND(NEW.quoted_amount_lyd * COALESCE(NEW.commission_rate, 0.1000), 2);
      IF NEW.commission_status IS NULL THEN
        NEW.commission_status := 'unpaid';
      END IF;
      IF NEW.commission_status = 'paid' THEN
        NEW.commission_paid_at := COALESCE(NEW.commission_paid_at, now());
      ELSIF NEW.commission_status IS DISTINCT FROM 'paid' THEN
        NEW.commission_paid_at := NULL;
      END IF;
    ELSE
      NEW.commission_amount_lyd := NULL;
      NEW.commission_status := NULL;
      NEW.commission_paid_at := NULL;
    END IF;
    RETURN NEW;
  END IF;

  IF admin_user THEN
    IF NEW.quoted_amount_lyd IS NOT NULL THEN
      NEW.commission_rate := COALESCE(NEW.commission_rate, OLD.commission_rate, 0.1000);
      NEW.commission_amount_lyd :=
        ROUND(NEW.quoted_amount_lyd * NEW.commission_rate, 2);
      IF NEW.commission_status IS NULL THEN
        NEW.commission_status := 'unpaid';
      END IF;
    ELSE
      NEW.commission_amount_lyd := NULL;
      NEW.commission_status := NULL;
      NEW.commission_paid_at := NULL;
    END IF;

    IF NEW.commission_status = 'paid' THEN
      NEW.commission_paid_at :=
        COALESCE(NEW.commission_paid_at, OLD.commission_paid_at, now());
    ELSE
      NEW.commission_paid_at := NULL;
    END IF;
    RETURN NEW;
  END IF;

  IF NOT vendor_owner THEN
    RAISE EXCEPTION 'only the vendor or an admin may update this booking';
  END IF;

  -- Vendor may not mark commission paid or waived.
  IF NEW.commission_status IN ('paid', 'waived')
     AND NEW.commission_status IS DISTINCT FROM OLD.commission_status THEN
    RAISE EXCEPTION 'only admin may set commission_status to paid or waived';
  END IF;

  IF OLD.status = 'pending' AND NEW.status = 'accepted' THEN
    IF NEW.quoted_amount_lyd IS NULL OR NEW.quoted_amount_lyd <= 0 THEN
      RAISE EXCEPTION 'quoted_amount_lyd is required when accepting a booking';
    END IF;
    NEW.commission_rate := 0.1000;
    NEW.commission_amount_lyd :=
      ROUND(NEW.quoted_amount_lyd * NEW.commission_rate, 2);
    NEW.commission_status := 'unpaid';
    NEW.commission_paid_at := NULL;
    RETURN NEW;
  END IF;

  -- Quote is locked after accept. Completing must not mark commission paid.
  NEW.quoted_amount_lyd := OLD.quoted_amount_lyd;
  NEW.commission_amount_lyd := OLD.commission_amount_lyd;
  NEW.commission_status := OLD.commission_status;
  NEW.commission_rate := OLD.commission_rate;
  NEW.commission_paid_at := OLD.commission_paid_at;

  IF NEW.status = 'declined' AND OLD.status = 'pending' THEN
    NEW.quoted_amount_lyd := NULL;
    NEW.commission_amount_lyd := NULL;
    NEW.commission_status := NULL;
    NEW.commission_paid_at := NULL;
  END IF;

  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS booking_protect_commission ON public.booking_requests;
CREATE TRIGGER booking_protect_commission
  BEFORE INSERT OR UPDATE ON public.booking_requests
  FOR EACH ROW EXECUTE FUNCTION public.protect_booking_commission();

-- Vendor accept: quote required; trigger computes 10% and sets unpaid.
CREATE OR REPLACE FUNCTION public.accept_booking_request(
  p_booking_id UUID,
  p_quoted_amount_lyd NUMERIC
)
RETURNS public.booking_requests
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  rec public.booking_requests;
BEGIN
  IF p_quoted_amount_lyd IS NULL OR p_quoted_amount_lyd <= 0 THEN
    RAISE EXCEPTION 'quoted_amount_lyd must be greater than 0';
  END IF;

  UPDATE public.booking_requests
  SET
    status = 'accepted',
    quoted_amount_lyd = p_quoted_amount_lyd
  WHERE id = p_booking_id
    AND status = 'pending'
    AND public.owns_vendor(vendor_id)
  RETURNING * INTO rec;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking not found, not pending, or not owned by vendor';
  END IF;

  RETURN rec;
END;
$$;

-- Admin records offline collection (or a waiver). Does not charge the couple.
CREATE OR REPLACE FUNCTION public.set_booking_commission_status(
  p_booking_id UUID,
  p_status public.commission_status
)
RETURNS public.booking_requests
LANGUAGE plpgsql
SECURITY INVOKER
SET search_path = public
AS $$
DECLARE
  rec public.booking_requests;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'only admin may update commission status';
  END IF;

  IF p_status NOT IN ('paid', 'waived') THEN
    RAISE EXCEPTION 'commission status must be paid or waived';
  END IF;

  UPDATE public.booking_requests
  SET commission_status = p_status
  WHERE id = p_booking_id
    AND quoted_amount_lyd IS NOT NULL
  RETURNING * INTO rec;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking not found or has no quoted amount';
  END IF;

  RETURN rec;
END;
$$;

GRANT EXECUTE ON FUNCTION public.accept_booking_request(UUID, NUMERIC) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_booking_commission_status(UUID, public.commission_status) TO authenticated;
