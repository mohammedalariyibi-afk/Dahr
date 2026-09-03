-- Split public-read policies so anon does not need EXECUTE on is_admin/owns_vendor.
-- Then revoke trigger/helper RPCs from anon (and from authenticated where they are not API).
-- Matches live Dahr LY migration `revoke_anon_definer_rpcs` (already applied on cloud).

DROP POLICY IF EXISTS vendors_public_read_approved ON public.vendor_profiles;
CREATE POLICY vendors_select_approved ON public.vendor_profiles
  FOR SELECT USING (is_approved = true);
CREATE POLICY vendors_select_own_or_admin ON public.vendor_profiles
  FOR SELECT USING (profile_id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS photos_public_read ON public.vendor_photos;
CREATE POLICY photos_select_approved_vendor ON public.vendor_photos
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.vendor_profiles v
      WHERE v.id = vendor_id AND v.is_approved = true
    )
  );
CREATE POLICY photos_select_owner_or_admin ON public.vendor_photos
  FOR SELECT USING (public.owns_vendor(vendor_id) OR public.is_admin());

DROP POLICY IF EXISTS availability_public_read ON public.availability;
CREATE POLICY availability_select_approved_vendor ON public.availability
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM public.vendor_profiles v
      WHERE v.id = vendor_id AND v.is_approved = true
    )
  );
CREATE POLICY availability_select_owner_or_admin ON public.availability
  FOR SELECT USING (public.owns_vendor(vendor_id) OR public.is_admin());

REVOKE ALL ON FUNCTION public.enforce_review_on_completed_booking() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.handle_new_user() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.protect_booking_commission() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.protect_vendor_admin_flags() FROM PUBLIC, anon, authenticated;
-- Hosted Dahr LY has this advisor leftover; skip if absent so local `db reset` still works.
DO $$
BEGIN
  IF to_regprocedure('public.rls_auto_enable()') IS NOT NULL THEN
    EXECUTE 'REVOKE ALL ON FUNCTION public.rls_auto_enable() FROM PUBLIC, anon, authenticated';
  END IF;
END
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.owns_vendor(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.owns_vendor(uuid) TO authenticated;

REVOKE ALL ON FUNCTION public.accept_booking_request(uuid, numeric) FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.set_booking_commission_status(uuid, public.commission_status) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.accept_booking_request(uuid, numeric) TO authenticated;
GRANT EXECUTE ON FUNCTION public.set_booking_commission_status(uuid, public.commission_status) TO authenticated;

-- Guest discover still increments views.
GRANT EXECUTE ON FUNCTION public.increment_vendor_views(uuid) TO anon, authenticated;
