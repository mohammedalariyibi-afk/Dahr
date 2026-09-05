-- Guests can browse approved listings, but must not receive WhatsApp
-- numbers. vendors_select_approved was created with no TO clause, so it
-- applies to role public (including anon). Combined with a table-wide
-- GRANT SELECT and no column grants, an unauthenticated caller gets the
-- whole row — confirmed live: 14 of 14 approved whatsapp_number values
-- readable as anon.
--
-- A column-level REVOKE is not enough when a table-level GRANT SELECT
-- is also present: Postgres still treats SELECT * as requesting every
-- column and fails. So we revoke the table grant from anon and put
-- back an explicit column list that omits whatsapp_number.
--
-- Signed-in users keep table-level SELECT (including the phone) and
-- also get a narrow vendor_contact view, matching the booking_party_contact
-- pattern. Flutter guest queries that use select('*') will 401 until they
-- list columns without whatsapp_number; signed-in select('*') is unchanged.

REVOKE SELECT ON TABLE public.vendor_profiles FROM anon;

GRANT SELECT (
  id,
  profile_id,
  business_name,
  category,
  city,
  description,
  price_min,
  price_max,
  services,
  is_verified,
  is_approved,
  view_count,
  created_at
) ON TABLE public.vendor_profiles TO anon;

CREATE OR REPLACE VIEW public.vendor_contact
WITH (security_invoker = true, security_barrier = true) AS
SELECT v.id, v.whatsapp_number
FROM public.vendor_profiles v
WHERE v.is_approved = true;

ALTER VIEW public.vendor_contact OWNER TO postgres;
REVOKE ALL ON TABLE public.vendor_contact FROM PUBLIC, anon;
GRANT SELECT ON TABLE public.vendor_contact TO authenticated, service_role;
