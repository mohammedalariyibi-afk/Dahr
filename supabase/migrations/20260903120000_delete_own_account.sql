-- Self-serve account deletion (Apple Guideline 5.1.1(v)).
-- SECURITY DEFINER is required so a signed-in user can delete their own
-- auth.users row. The function takes NO user-id argument and only deletes
-- auth.uid(). Keep this contract in sync with DeleteAccountRpcSpec in
-- lib/features/auth/account_deletion.dart.
--
-- GRANT EXECUTE to authenticated only — never anon. Revoke PUBLIC because
-- Postgres defaults new functions to EXECUTE for PUBLIC.

CREATE OR REPLACE FUNCTION public.delete_own_account()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = ''
AS $$
DECLARE
  uid uuid;
BEGIN
  uid := auth.uid();
  IF uid IS NULL THEN
    RAISE EXCEPTION 'not authenticated';
  END IF;

  -- Auth users who own Storage objects cannot be deleted. Vendor photos
  -- live at vendor-photos/{auth.uid()}/*. Removing the metadata rows
  -- unblocks the user delete; listing rows cascade from profiles.
  DELETE FROM storage.objects
  WHERE bucket_id = 'vendor-photos'
    AND (
      name LIKE (uid::text || '/%')
      OR owner = uid
    );

  DELETE FROM auth.users WHERE id = uid;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'account not found';
  END IF;
END;
$$;

COMMENT ON FUNCTION public.delete_own_account() IS
  'Deletes the signed-in auth user (auth.uid() only). Cascades public.profiles and vendor listings. No user-id argument — cannot delete someone else.';

REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.delete_own_account() FROM anon;
REVOKE ALL ON FUNCTION public.delete_own_account() FROM authenticated;
GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated;
