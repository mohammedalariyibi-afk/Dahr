-- Couple identity for a vendor inbox: display name + mobile number.
-- Guests must not see phones. Review author names stay on profile_public
-- (id, full_name only). This view is authenticated-only.
--
-- A row is visible when the caller is that couple, the vendor who owns a
-- booking with them, or an admin. Random signed-in users get nothing.
--
-- Does not change Storage. Safe to apply on Dahr LY after guest-read.

CREATE OR REPLACE FUNCTION private.booking_party_contact_rows()
RETURNS TABLE(id uuid, full_name text, phone text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.id, p.full_name, p.phone
  FROM public.profiles p
  WHERE EXISTS (
    SELECT 1 FROM public.booking_requests b
    WHERE b.consumer_id = p.id
      AND (
        b.consumer_id = auth.uid()
        OR public.owns_vendor(b.vendor_id)
        OR public.is_admin()
      )
  );
$$;

REVOKE ALL ON FUNCTION private.booking_party_contact_rows() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.booking_party_contact_rows() TO authenticated, service_role;

CREATE OR REPLACE VIEW public.booking_party_contact
WITH (security_invoker = true, security_barrier = true)
AS
SELECT r.id, r.full_name, r.phone
FROM private.booking_party_contact_rows() AS r;

ALTER VIEW public.booking_party_contact OWNER TO postgres;
REVOKE ALL ON public.booking_party_contact FROM PUBLIC;
GRANT SELECT ON public.booking_party_contact TO authenticated, service_role;
