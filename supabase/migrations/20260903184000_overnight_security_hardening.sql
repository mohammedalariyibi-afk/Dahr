-- overnight_security_hardening
-- Matches live Dahr LY SQL of the same name (already applied on cloud as
-- 20260903164203). Safe to re-run: CREATE OR REPLACE / DROP IF EXISTS.
--
-- Does NOT re-apply init schema.
-- Does NOT re-grant is_admin() / owns_vendor() to anon (live also has a
-- historical grant_rls_helpers_to_anon; revoke_anon_definer_rpcs undid it).

-- ---------------------------------------------------------------------------
-- 1. reject_booking_if_date_booked is trigger-only — not a client RPC.
-- Live already has the function + BEFORE INSERT trigger. Recreate the same
-- body so local `db reset` (which only has init + later repo migrations)
-- gets the date race guard too.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.reject_booking_if_date_booked()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.status = 'pending'::public.booking_status AND EXISTS (
    SELECT 1
    FROM public.availability a
    WHERE a.vendor_id = NEW.vendor_id
      AND a.date = NEW.event_date
      AND a.status = 'booked'::public.availability_status
  ) THEN
    RAISE EXCEPTION 'date_unavailable';
  END IF;
  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION public.reject_booking_if_date_booked() IS
  'BEFORE INSERT trigger on booking_requests. Rejects pending requests for a date the vendor marked booked. Not a client RPC.';

DROP TRIGGER IF EXISTS booking_reject_if_date_booked ON public.booking_requests;
CREATE TRIGGER booking_reject_if_date_booked
  BEFORE INSERT ON public.booking_requests
  FOR EACH ROW
  EXECUTE FUNCTION public.reject_booking_if_date_booked();

REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM anon;
REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM authenticated;

-- Belt-and-suspenders: never re-grant RLS helpers to anon.
REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.owns_vendor(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.owns_vendor(uuid) TO authenticated;

-- ---------------------------------------------------------------------------
-- 2. Replace profile_public SECURITY DEFINER / security_barrier view with
--    a security_invoker view of id + full_name only.
-- ---------------------------------------------------------------------------
DROP VIEW IF EXISTS public.profile_public;
CREATE VIEW public.profile_public
WITH (security_invoker = true) AS
SELECT id, full_name
FROM public.profiles;

COMMENT ON VIEW public.profile_public IS
  'Display names only. security_invoker=true so profiles RLS applies.';

GRANT SELECT ON public.profile_public TO anon, authenticated;

-- ---------------------------------------------------------------------------
-- 3. profiles_select_public_names — reviews, approved vendors, and booking
--    counterparties can still read display names through the invoker view
--    and PostgREST embeds (profiles(full_name)).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_select_public_names ON public.profiles;
CREATE POLICY profiles_select_public_names ON public.profiles
  FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.reviews r
      WHERE r.consumer_id = profiles.id
        AND r.is_hidden = false
    )
    OR EXISTS (
      SELECT 1
      FROM public.vendor_profiles v
      WHERE v.profile_id = profiles.id
        AND v.is_approved = true
    )
    OR EXISTS (
      SELECT 1
      FROM public.booking_requests b
      WHERE b.consumer_id = profiles.id
        AND (
          b.consumer_id = auth.uid()
          OR public.owns_vendor(b.vendor_id)
          OR public.is_admin()
        )
    )
  );
