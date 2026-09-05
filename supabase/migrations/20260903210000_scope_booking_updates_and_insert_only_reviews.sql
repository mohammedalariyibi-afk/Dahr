-- Couples must not UPDATE booking rows (accept/decline/complete is vendor or admin).
DROP POLICY IF EXISTS bookings_update_parties ON public.booking_requests;

-- Reviews are insert-only for authors. Hide/edit is admin-only.
DROP POLICY IF EXISTS reviews_admin_update ON public.reviews;
CREATE POLICY reviews_admin_update ON public.reviews
  FOR UPDATE TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

CREATE OR REPLACE FUNCTION public.protect_review_moderation()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;
  IF public.is_admin() THEN
    RETURN NEW;
  END IF;
  RAISE EXCEPTION 'only admin may update reviews';
END;
$$;

REVOKE ALL ON FUNCTION public.protect_review_moderation() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.protect_review_moderation() TO service_role;

DROP TRIGGER IF EXISTS reviews_protect_moderation ON public.reviews;
CREATE TRIGGER reviews_protect_moderation
  BEFORE UPDATE ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.protect_review_moderation();
