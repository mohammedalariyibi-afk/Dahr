-- freeze_admin_role_and_private_profile_rows
-- Combined repo file matching live Dahr LY final state.
-- Live already applied this as two Syber migrations; do NOT db push / re-apply
-- on Dahr LY. One timestamp after overnight_security_hardening so local
-- `db reset` matches. Does not change Storage buckets.

-- ---------------------------------------------------------------------------
-- 1. Non-admins cannot self-promote to profiles.role = admin.
-- Trigger-only: no client EXECUTE.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.protect_profile_admin_role()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' AND NEW.role = 'admin'::public.user_role AND NOT public.is_admin() THEN
    NEW.role := 'consumer'::public.user_role;
  ELSIF TG_OP = 'UPDATE'
    AND NEW.role = 'admin'::public.user_role
    AND OLD.role IS DISTINCT FROM 'admin'::public.user_role
    AND NOT public.is_admin()
  THEN
    NEW.role := OLD.role;
  END IF;

  RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.protect_profile_admin_role() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.protect_profile_admin_role() TO service_role;

DROP TRIGGER IF EXISTS profiles_protect_admin_role ON public.profiles;
CREATE TRIGGER profiles_protect_admin_role
  BEFORE INSERT OR UPDATE OF role ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_profile_admin_role();

-- ---------------------------------------------------------------------------
-- 2. Drop table-level public-names policy (column leak). Display names go
--    through private.public_profile_rows() + profile_public invoker view.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS profiles_select_public_names ON public.profiles;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC;
GRANT USAGE ON SCHEMA private TO anon, authenticated, service_role;

CREATE OR REPLACE FUNCTION private.public_profile_rows()
RETURNS TABLE(id uuid, full_name text)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = ''
AS $$
  SELECT p.id, p.full_name
  FROM public.profiles p
  WHERE EXISTS (
    SELECT 1 FROM public.reviews r
    WHERE r.consumer_id = p.id AND r.is_hidden = false
  )
  OR EXISTS (
    SELECT 1 FROM public.vendor_profiles v
    WHERE v.profile_id = p.id AND v.is_approved = true
  )
  OR EXISTS (
    SELECT 1 FROM public.booking_requests b
    WHERE b.consumer_id = p.id
      AND (
        b.consumer_id = auth.uid()
        OR public.owns_vendor(b.vendor_id)
        OR public.is_admin()
      )
  );
$$;

REVOKE ALL ON FUNCTION private.public_profile_rows() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION private.public_profile_rows() TO anon, authenticated, service_role;

CREATE OR REPLACE VIEW public.profile_public
WITH (security_invoker = true, security_barrier = true)
AS
SELECT r.id, r.full_name
FROM private.public_profile_rows() AS r;

ALTER VIEW public.profile_public OWNER TO postgres;
REVOKE ALL ON public.profile_public FROM PUBLIC;
GRANT SELECT ON public.profile_public TO anon, authenticated, service_role;
