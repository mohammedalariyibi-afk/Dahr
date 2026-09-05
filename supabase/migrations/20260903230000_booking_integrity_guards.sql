-- Booking integrity: close PostgREST bypasses that Flutter write guards
-- cannot enforce. Safe to apply on live Dahr LY (CREATE OR REPLACE /
-- DROP IF EXISTS / CREATE INDEX IF NOT EXISTS). Seed still works because
-- postgres/service inserts see auth.uid() IS NULL.

-- ---------------------------------------------------------------------------
-- 1. One accepted/completed booking per vendor per date
-- ---------------------------------------------------------------------------
CREATE UNIQUE INDEX IF NOT EXISTS booking_requests_one_held_date
  ON public.booking_requests (vendor_id, event_date)
  WHERE status IN (
    'accepted'::public.booking_status,
    'completed'::public.booking_status
  );

CREATE INDEX IF NOT EXISTS idx_booking_requests_vendor_event_active
  ON public.booking_requests (vendor_id, event_date)
  WHERE status IN (
    'accepted'::public.booking_status,
    'completed'::public.booking_status
  );

-- ---------------------------------------------------------------------------
-- 2. Date guard: availability booked OR another held booking
--    Runs on INSERT and on UPDATE (accept). Accepting a date the vendor
--    already marked booked is allowed — that is the intended confirm path.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_booking_if_date_booked()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF TG_OP = 'INSERT'
     AND NEW.status = 'pending'::public.booking_status
     AND EXISTS (
       SELECT 1
       FROM public.availability a
       WHERE a.vendor_id = NEW.vendor_id
         AND a.date = NEW.event_date
         AND a.status = 'booked'::public.availability_status
     ) THEN
    RAISE EXCEPTION 'date_unavailable';
  END IF;

  IF NEW.status IN (
       'pending'::public.booking_status,
       'accepted'::public.booking_status,
       'completed'::public.booking_status
     )
     AND EXISTS (
       SELECT 1
       FROM public.booking_requests b
       WHERE b.vendor_id = NEW.vendor_id
         AND b.event_date = NEW.event_date
         AND b.status IN (
           'accepted'::public.booking_status,
           'completed'::public.booking_status
         )
         AND (TG_OP = 'INSERT' OR b.id IS DISTINCT FROM NEW.id)
     ) THEN
    RAISE EXCEPTION 'date_unavailable';
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.reject_booking_if_date_booked() IS
  'BEFORE INSERT OR UPDATE on booking_requests. Rejects pending requests for a vendor-marked booked date, and any row that would collide with an accepted/completed booking on the same date. Not a client RPC.';

DROP TRIGGER IF EXISTS booking_reject_if_date_booked ON public.booking_requests;
CREATE TRIGGER booking_reject_if_date_booked
  BEFORE INSERT OR UPDATE ON public.booking_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.reject_booking_if_date_booked();

REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.reject_booking_if_date_booked() TO service_role;

-- ---------------------------------------------------------------------------
-- 3. Commission + status machine + identity lock + approved-vendor insert
-- ---------------------------------------------------------------------------
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

    -- Couples creating a request: never attach money; must be pending
    -- against an approved listing.
    NEW.quoted_amount_lyd := NULL;
    NEW.commission_amount_lyd := NULL;
    NEW.commission_status := NULL;
    NEW.commission_paid_at := NULL;
    NEW.commission_rate := 0.1000;
    IF NEW.status IS DISTINCT FROM 'pending'::public.booking_status THEN
      RAISE EXCEPTION 'booking_must_be_pending';
    END IF;
    IF NOT EXISTS (
      SELECT 1
      FROM public.vendor_profiles v
      WHERE v.id = NEW.vendor_id AND v.is_approved = true
    ) THEN
      RAISE EXCEPTION 'vendor_not_approved';
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

  IF NOT admin_user THEN
    NEW.consumer_id := OLD.consumer_id;
    NEW.vendor_id := OLD.vendor_id;
    NEW.event_date := OLD.event_date;
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

  IF NEW.commission_status IN ('paid', 'waived')
     AND NEW.commission_status IS DISTINCT FROM OLD.commission_status THEN
    RAISE EXCEPTION 'only admin may set commission_status to paid or waived';
  END IF;

  IF OLD.status = 'pending'::public.booking_status
     AND NEW.status = 'accepted'::public.booking_status THEN
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

  NEW.quoted_amount_lyd := OLD.quoted_amount_lyd;
  NEW.commission_amount_lyd := OLD.commission_amount_lyd;
  NEW.commission_status := OLD.commission_status;
  NEW.commission_rate := OLD.commission_rate;
  NEW.commission_paid_at := OLD.commission_paid_at;

  IF OLD.status = 'pending'::public.booking_status
     AND NEW.status = 'declined'::public.booking_status THEN
    NEW.quoted_amount_lyd := NULL;
    NEW.commission_amount_lyd := NULL;
    NEW.commission_status := NULL;
    NEW.commission_paid_at := NULL;
    RETURN NEW;
  END IF;

  IF OLD.status = 'accepted'::public.booking_status
     AND NEW.status = 'completed'::public.booking_status THEN
    RETURN NEW;
  END IF;

  IF OLD.status IS DISTINCT FROM NEW.status THEN
    RAISE EXCEPTION 'invalid_booking_transition';
  END IF;

  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 4. Accept RPC: mark the calendar booked in the same transaction
-- ---------------------------------------------------------------------------
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

  INSERT INTO public.availability (vendor_id, date, status)
  VALUES (rec.vendor_id, rec.event_date, 'booked'::public.availability_status)
  ON CONFLICT (vendor_id, date)
  DO UPDATE SET status = 'booked'::public.availability_status;

  RETURN rec;
END;
$$;

-- ---------------------------------------------------------------------------
-- 5. Reviews: authors cannot hide on insert
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.enforce_review_on_completed_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  br public.booking_requests%ROWTYPE;
BEGIN
  SELECT * INTO br FROM public.booking_requests WHERE id = NEW.booking_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_request not found';
  END IF;
  IF br.status <> 'completed' THEN
    RAISE EXCEPTION 'reviews only allowed for completed bookings';
  END IF;
  IF br.consumer_id <> NEW.consumer_id THEN
    RAISE EXCEPTION 'review consumer must match booking consumer';
  END IF;
  IF br.vendor_id <> NEW.vendor_id THEN
    RAISE EXCEPTION 'review vendor must match booking vendor';
  END IF;
  IF auth.uid() IS NOT NULL AND NOT public.is_admin() THEN
    NEW.is_hidden := false;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 6. view_count only via increment_vendor_views
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.increment_vendor_views(p_vendor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM set_config('dahr.allow_view_increment', 'on', true);
  UPDATE public.vendor_profiles
  SET view_count = view_count + 1
  WHERE id = p_vendor_id AND is_approved = true;
END;
$$;

CREATE OR REPLACE FUNCTION public.protect_vendor_admin_flags()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NOT public.is_admin() THEN
      NEW.is_approved := false;
      NEW.is_verified := false;
      NEW.view_count := 0;
    END IF;
    RETURN NEW;
  END IF;

  IF NOT public.is_admin() THEN
    NEW.is_approved := OLD.is_approved;
    NEW.is_verified := OLD.is_verified;
    IF current_setting('dahr.allow_view_increment', true) IS DISTINCT FROM 'on' THEN
      NEW.view_count := OLD.view_count;
    END IF;
  END IF;
  RETURN NEW;
END;
$$;

-- ---------------------------------------------------------------------------
-- 7. Vendors cannot free a date that has an accepted/completed booking
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_availability_held_dates()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  vendor UUID;
  slot_date DATE;
  freeing BOOLEAN;
BEGIN
  IF TG_OP = 'DELETE' THEN
    vendor := OLD.vendor_id;
    slot_date := OLD.date;
    freeing := OLD.status = 'booked'::public.availability_status;
  ELSE
    vendor := NEW.vendor_id;
    slot_date := NEW.date;
    freeing := NEW.status = 'available'::public.availability_status
      AND (TG_OP = 'INSERT' OR OLD.status IS DISTINCT FROM 'available'::public.availability_status);
  END IF;

  IF freeing AND EXISTS (
    SELECT 1
    FROM public.booking_requests b
    WHERE b.vendor_id = vendor
      AND b.event_date = slot_date
      AND b.status IN (
        'accepted'::public.booking_status,
        'completed'::public.booking_status
      )
  ) THEN
    RAISE EXCEPTION 'date_has_accepted_booking';
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS availability_protect_held_dates ON public.availability;
CREATE TRIGGER availability_protect_held_dates
  BEFORE INSERT OR UPDATE OR DELETE ON public.availability
  FOR EACH ROW
  EXECUTE FUNCTION public.protect_availability_held_dates();

REVOKE ALL ON FUNCTION public.protect_availability_held_dates() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.protect_availability_held_dates() TO service_role;
