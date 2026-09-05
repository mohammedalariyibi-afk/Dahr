-- Three storage problems, one migration.
--
-- 1. vendor-photos is public with no size or MIME limit. Any signed-in
--    account — not just a vendor — can upload any file of any size into
--    a permanently public URL, because the insert policy only checks that
--    the folder name matches auth.uid().
-- 2. vendor_photos_storage_admin_all is FOR ALL with no TO clause and
--    calls is_admin(), which anon cannot execute. That is the exact
--    guest-browse footgun 20260904010000 fixed for tables and missed
--    for storage. Latent today because the bucket is empty.
-- 3. vendor_photos.storage_url is free text. A vendor can point it at
--    a host they control and harvest the IP of every guest on Discover.
--    All 16 current rows are Unsplash seed URLs, so the CHECK allows
--    those plus this project's storage URLs and local-dev storage.
--
-- The bucket stays public=true. Flipping it would break getPublicUrl
-- in the Flutter client. Unapproved vendors' files remain fetchable
-- by URL; the approval gate is on the metadata row, not the file.

UPDATE storage.buckets
SET file_size_limit = 5242880,
    allowed_mime_types = ARRAY['image/jpeg', 'image/png', 'image/webp']
WHERE id = 'vendor-photos';

DROP POLICY IF EXISTS vendor_photos_storage_owner_insert ON storage.objects;
CREATE POLICY vendor_photos_storage_owner_insert
  ON storage.objects
  FOR INSERT
  TO authenticated
  WITH CHECK (
    bucket_id = 'vendor-photos'
    AND (SELECT auth.uid())::text = (storage.foldername(name))[1]
    AND EXISTS (
      SELECT 1
      FROM public.vendor_profiles v
      WHERE v.profile_id = (SELECT auth.uid())
    )
  );

DROP POLICY IF EXISTS vendor_photos_storage_owner_update ON storage.objects;
CREATE POLICY vendor_photos_storage_owner_update
  ON storage.objects
  FOR UPDATE
  TO authenticated
  USING (
    bucket_id = 'vendor-photos'
    AND (SELECT auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS vendor_photos_storage_owner_delete ON storage.objects;
CREATE POLICY vendor_photos_storage_owner_delete
  ON storage.objects
  FOR DELETE
  TO authenticated
  USING (
    bucket_id = 'vendor-photos'
    AND (SELECT auth.uid())::text = (storage.foldername(name))[1]
  );

DROP POLICY IF EXISTS vendor_photos_storage_admin_all ON storage.objects;
CREATE POLICY vendor_photos_storage_admin_all
  ON storage.objects
  FOR ALL
  TO authenticated
  USING (bucket_id = 'vendor-photos' AND public.is_admin())
  WITH CHECK (bucket_id = 'vendor-photos' AND public.is_admin());

ALTER TABLE public.vendor_photos
  DROP CONSTRAINT IF EXISTS vendor_photo_url_host;

ALTER TABLE public.vendor_photos
  ADD CONSTRAINT vendor_photo_url_host CHECK (
    storage_url LIKE 'https://images.unsplash.com/%'
    OR storage_url LIKE 'https://%.supabase.co/storage/v1/object/public/vendor-photos/%'
    OR storage_url LIKE 'http://127.0.0.1:%/storage/v1/object/public/vendor-photos/%'
    OR storage_url LIKE 'http://localhost:%/storage/v1/object/public/vendor-photos/%'
  );
