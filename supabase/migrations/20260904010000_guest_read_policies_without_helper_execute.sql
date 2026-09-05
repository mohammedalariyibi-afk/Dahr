-- Guest browse is broken on Dahr LY: every anonymous read fails with
-- `permission denied for function is_admin`.
--
-- `revoke_anon_definer_rpcs` correctly took EXECUTE on is_admin() and
-- owns_vendor() away from anon, and split the public-read policies so a guest
-- can be allowed by a policy that calls neither. But permissive policies are
-- OR-ed into one qual, and both helpers take no arguments (or only a column),
-- so Postgres checks EXECUTE while it prepares the query -- before any row or
-- any OR branch is considered. A guest therefore cannot read vendor_profiles,
-- vendor_photos, availability, or reviews at all: Discover, vendor detail,
-- photos, the booking calendar, and review lists all error out.
--
-- Fix: restrict every helper-calling policy to the `authenticated` role, so
-- the qual a guest is planned with contains no helper call. Nothing changes
-- for signed-in users -- for them these policies still apply and still OR
-- with the public ones.
--
-- Safe to apply on live Dahr LY: DROP POLICY IF EXISTS + CREATE POLICY only,
-- no data and no bucket changes.

-- ---------------------------------------------------------------------------
-- vendor_profiles: approved listings stay world-readable
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS vendors_select_own_or_admin ON public.vendor_profiles;
CREATE POLICY vendors_select_own_or_admin ON public.vendor_profiles
  FOR SELECT TO authenticated
  USING (profile_id = auth.uid() OR public.is_admin());

-- ---------------------------------------------------------------------------
-- vendor_photos
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS photos_select_owner_or_admin ON public.vendor_photos;
CREATE POLICY photos_select_owner_or_admin ON public.vendor_photos
  FOR SELECT TO authenticated
  USING (public.owns_vendor(vendor_id) OR public.is_admin());

-- ---------------------------------------------------------------------------
-- availability: `availability_owner_write` is FOR ALL, so it is part of the
-- SELECT qual too and has to be scoped as well.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS availability_select_owner_or_admin ON public.availability;
CREATE POLICY availability_select_owner_or_admin ON public.availability
  FOR SELECT TO authenticated
  USING (public.owns_vendor(vendor_id) OR public.is_admin());

DROP POLICY IF EXISTS availability_owner_write ON public.availability;
CREATE POLICY availability_owner_write ON public.availability
  FOR ALL TO authenticated
  USING (public.owns_vendor(vendor_id) OR public.is_admin())
  WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());

-- ---------------------------------------------------------------------------
-- reviews: split the single public-read policy the same way
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS reviews_public_read ON public.reviews;
DROP POLICY IF EXISTS reviews_select_visible ON public.reviews;
CREATE POLICY reviews_select_visible ON public.reviews
  FOR SELECT
  USING (NOT is_hidden);

DROP POLICY IF EXISTS reviews_select_own_or_admin ON public.reviews;
CREATE POLICY reviews_select_own_or_admin ON public.reviews
  FOR SELECT TO authenticated
  USING (
    consumer_id = auth.uid()
    OR public.owns_vendor(vendor_id)
    OR public.is_admin()
  );

-- ---------------------------------------------------------------------------
-- Tables a guest has no business reading. Scoped for the same reason, so an
-- accidental anonymous read returns nothing instead of a permission error.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_select_own_or_admin ON public.profiles;
CREATE POLICY profiles_select_own_or_admin ON public.profiles
  FOR SELECT TO authenticated
  USING (id = auth.uid() OR public.is_admin());

DROP POLICY IF EXISTS profiles_admin_all ON public.profiles;
CREATE POLICY profiles_admin_all ON public.profiles
  FOR ALL TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS bookings_select_parties ON public.booking_requests;
CREATE POLICY bookings_select_parties ON public.booking_requests
  FOR SELECT TO authenticated
  USING (
    consumer_id = auth.uid()
    OR public.owns_vendor(vendor_id)
    OR public.is_admin()
  );

DROP POLICY IF EXISTS favorites_admin_read ON public.favorites;
CREATE POLICY favorites_admin_read ON public.favorites
  FOR SELECT TO authenticated
  USING (public.is_admin());

DROP POLICY IF EXISTS reports_select_own_or_admin ON public.reports;
CREATE POLICY reports_select_own_or_admin ON public.reports
  FOR SELECT TO authenticated
  USING (reported_by = auth.uid() OR public.is_admin());
