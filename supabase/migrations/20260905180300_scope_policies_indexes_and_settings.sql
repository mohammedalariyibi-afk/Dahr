-- Policy scoping, InitPlan wrapping, review approval gate, bank-details
-- read scope, and the four missing FK indexes.
--
-- Write policies that call owns_vendor() / is_admin() were left on role
-- public. Anon cannot execute those helpers, so a guest write returns
-- `permission denied for function owns_vendor` instead of a clean RLS
-- denial. Fail-closed, but it maps internals and breaks client errors.
-- Scope them to authenticated — the only role that can satisfy them.
--
-- While rewriting, wrap auth.uid() as (SELECT auth.uid()) so Postgres
-- caches it once per statement instead of re-evaluating per row.
--
-- reviews_select_visible checked only NOT is_hidden. Every sibling guest
-- policy also gates on vendor is_approved. After a revocation the listing
-- disappeared but the reviews (and reviewer names) stayed queryable.
--
-- platform_settings SELECT was USING (true) for every signed-in user.
-- Couples who owe a fee need the bank details; vendors never do. Admins
-- keep SELECT so the admin panel's UPDATE ... RETURNING still works
-- (Postgres UPDATE must first SELECT the row).
--
-- CREATE INDEX CONCURRENTLY cannot run inside a migration transaction.
-- These four tables are empty or one row; a regular CREATE INDEX is fine.

-- ---------------------------------------------------------------------------
-- vendor_profiles writes
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS vendors_insert_own ON public.vendor_profiles;
CREATE POLICY vendors_insert_own ON public.vendor_profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (profile_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS vendors_update_own ON public.vendor_profiles;
CREATE POLICY vendors_update_own ON public.vendor_profiles
  FOR UPDATE
  TO authenticated
  USING (profile_id = (SELECT auth.uid()) OR public.is_admin())
  WITH CHECK (profile_id = (SELECT auth.uid()) OR public.is_admin());

DROP POLICY IF EXISTS vendors_delete_own_or_admin ON public.vendor_profiles;
CREATE POLICY vendors_delete_own_or_admin ON public.vendor_profiles
  FOR DELETE
  TO authenticated
  USING (profile_id = (SELECT auth.uid()) OR public.is_admin());

DROP POLICY IF EXISTS vendors_select_own_or_admin ON public.vendor_profiles;
CREATE POLICY vendors_select_own_or_admin ON public.vendor_profiles
  FOR SELECT
  TO authenticated
  USING (profile_id = (SELECT auth.uid()) OR public.is_admin());

-- ---------------------------------------------------------------------------
-- vendor_photos writes
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS photos_owner_insert ON public.vendor_photos;
CREATE POLICY photos_owner_insert ON public.vendor_photos
  FOR INSERT
  TO authenticated
  WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());

DROP POLICY IF EXISTS photos_owner_update ON public.vendor_photos;
CREATE POLICY photos_owner_update ON public.vendor_photos
  FOR UPDATE
  TO authenticated
  USING (public.owns_vendor(vendor_id) OR public.is_admin())
  WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());

DROP POLICY IF EXISTS photos_owner_delete ON public.vendor_photos;
CREATE POLICY photos_owner_delete ON public.vendor_photos
  FOR DELETE
  TO authenticated
  USING (public.owns_vendor(vendor_id) OR public.is_admin());

-- ---------------------------------------------------------------------------
-- bookings
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS bookings_insert_consumer ON public.booking_requests;
CREATE POLICY bookings_insert_consumer ON public.booking_requests
  FOR INSERT
  TO authenticated
  WITH CHECK (consumer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS bookings_update_vendor_or_admin ON public.booking_requests;
CREATE POLICY bookings_update_vendor_or_admin ON public.booking_requests
  FOR UPDATE
  TO authenticated
  USING (public.owns_vendor(vendor_id) OR public.is_admin())
  WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());

DROP POLICY IF EXISTS bookings_select_parties ON public.booking_requests;
CREATE POLICY bookings_select_parties ON public.booking_requests
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = (SELECT auth.uid())
    OR public.owns_vendor(vendor_id)
    OR public.is_admin()
  );

-- ---------------------------------------------------------------------------
-- profiles / favorites / reports / reviews
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_insert_own ON public.profiles;
CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT
  TO authenticated
  WITH CHECK (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS profiles_update_own ON public.profiles;
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE
  TO authenticated
  USING (id = (SELECT auth.uid()))
  WITH CHECK (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS profiles_select_own_or_admin ON public.profiles;
CREATE POLICY profiles_select_own_or_admin ON public.profiles
  FOR SELECT
  TO authenticated
  USING (id = (SELECT auth.uid()) OR public.is_admin());

DROP POLICY IF EXISTS favorites_own ON public.favorites;
CREATE POLICY favorites_own ON public.favorites
  FOR ALL
  TO authenticated
  USING (consumer_id = (SELECT auth.uid()))
  WITH CHECK (consumer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS reports_insert_auth ON public.reports;
CREATE POLICY reports_insert_auth ON public.reports
  FOR INSERT
  TO authenticated
  WITH CHECK (reported_by = (SELECT auth.uid()));

DROP POLICY IF EXISTS reports_admin_update ON public.reports;
CREATE POLICY reports_admin_update ON public.reports
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

DROP POLICY IF EXISTS reports_select_own_or_admin ON public.reports;
CREATE POLICY reports_select_own_or_admin ON public.reports
  FOR SELECT
  TO authenticated
  USING (reported_by = (SELECT auth.uid()) OR public.is_admin());

DROP POLICY IF EXISTS reviews_insert_consumer ON public.reviews;
CREATE POLICY reviews_insert_consumer ON public.reviews
  FOR INSERT
  TO authenticated
  WITH CHECK (consumer_id = (SELECT auth.uid()));

DROP POLICY IF EXISTS reviews_select_own_or_admin ON public.reviews;
CREATE POLICY reviews_select_own_or_admin ON public.reviews
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = (SELECT auth.uid())
    OR public.owns_vendor(vendor_id)
    OR public.is_admin()
  );

DROP POLICY IF EXISTS reviews_select_visible ON public.reviews;
CREATE POLICY reviews_select_visible ON public.reviews
  FOR SELECT
  TO anon, authenticated
  USING (
    NOT is_hidden
    AND EXISTS (
      SELECT 1
      FROM public.vendor_profiles v
      WHERE v.id = reviews.vendor_id
        AND v.is_approved = true
    )
  );

-- ---------------------------------------------------------------------------
-- commission notes + platform bank details
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS commission_transfer_notes_select_own_or_admin
  ON public.commission_transfer_notes;
CREATE POLICY commission_transfer_notes_select_own_or_admin
  ON public.commission_transfer_notes
  FOR SELECT
  TO authenticated
  USING (consumer_id = (SELECT auth.uid()) OR public.is_admin());

DROP POLICY IF EXISTS commission_transfer_notes_insert_own_unpaid
  ON public.commission_transfer_notes;
CREATE POLICY commission_transfer_notes_insert_own_unpaid
  ON public.commission_transfer_notes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    consumer_id = (SELECT auth.uid())
    AND EXISTS (
      SELECT 1
      FROM public.booking_requests b
      WHERE b.id = booking_id
        AND b.consumer_id = (SELECT auth.uid())
        AND b.quoted_amount_lyd IS NOT NULL
        AND b.commission_status = 'unpaid'
    )
  );

DROP POLICY IF EXISTS platform_settings_select_authenticated
  ON public.platform_settings;
DROP POLICY IF EXISTS platform_settings_select_paying_party
  ON public.platform_settings;
CREATE POLICY platform_settings_select_paying_party
  ON public.platform_settings
  FOR SELECT
  TO authenticated
  USING (
    public.is_admin()
    OR EXISTS (
      SELECT 1
      FROM public.booking_requests b
      WHERE b.consumer_id = (SELECT auth.uid())
        AND b.quoted_amount_lyd IS NOT NULL
        AND b.commission_status = 'unpaid'
    )
  );

-- ---------------------------------------------------------------------------
-- FK indexes
-- ---------------------------------------------------------------------------
CREATE INDEX IF NOT EXISTS idx_commission_transfer_notes_consumer
  ON public.commission_transfer_notes (consumer_id);
CREATE INDEX IF NOT EXISTS idx_favorites_vendor
  ON public.favorites (vendor_id);
CREATE INDEX IF NOT EXISTS idx_reports_reporter
  ON public.reports (reported_by);
CREATE INDEX IF NOT EXISTS idx_reviews_consumer
  ON public.reviews (consumer_id);
