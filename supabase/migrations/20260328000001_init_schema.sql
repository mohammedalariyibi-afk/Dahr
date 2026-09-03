-- Dahr wedding marketplace schema
CREATE TYPE public.user_role AS ENUM ('consumer', 'vendor', 'admin');
CREATE TYPE public.vendor_category AS ENUM (
  'venues', 'photography', 'catering', 'dresses', 'beauty', 'music', 'cars', 'decor', 'other'
);
CREATE TYPE public.city_code AS ENUM ('tripoli', 'benghazi');
CREATE TYPE public.booking_status AS ENUM ('pending', 'accepted', 'declined', 'completed');
CREATE TYPE public.availability_status AS ENUM ('available', 'booked');
CREATE TYPE public.report_target AS ENUM ('vendor', 'review');
CREATE TYPE public.report_status AS ENUM ('open', 'dismissed', 'actioned');

CREATE TABLE public.profiles (
  id UUID PRIMARY KEY REFERENCES auth.users (id) ON DELETE CASCADE,
  phone TEXT,
  full_name TEXT,
  role public.user_role NOT NULL DEFAULT 'consumer',
  city public.city_code,
  wedding_date DATE,
  locale TEXT NOT NULL DEFAULT 'ar',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.vendor_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  profile_id UUID NOT NULL UNIQUE REFERENCES public.profiles (id) ON DELETE CASCADE,
  business_name TEXT NOT NULL,
  category public.vendor_category NOT NULL,
  city public.city_code NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  price_min NUMERIC(12, 2),
  price_max NUMERIC(12, 2),
  whatsapp_number TEXT,
  services TEXT[] NOT NULL DEFAULT '{}',
  is_verified BOOLEAN NOT NULL DEFAULT false,
  is_approved BOOLEAN NOT NULL DEFAULT false,
  view_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT vendor_price_range_check CHECK (
    price_min IS NULL OR price_max IS NULL OR price_min <= price_max
  )
);

CREATE TABLE public.vendor_photos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendor_profiles (id) ON DELETE CASCADE,
  storage_url TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.availability (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendor_profiles (id) ON DELETE CASCADE,
  date DATE NOT NULL,
  status public.availability_status NOT NULL DEFAULT 'booked',
  UNIQUE (vendor_id, date)
);

CREATE TABLE public.booking_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendor_profiles (id) ON DELETE CASCADE,
  consumer_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  event_date DATE NOT NULL,
  guest_count INTEGER,
  message TEXT NOT NULL DEFAULT '',
  status public.booking_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.reviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  vendor_id UUID NOT NULL REFERENCES public.vendor_profiles (id) ON DELETE CASCADE,
  consumer_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  booking_request_id UUID NOT NULL UNIQUE REFERENCES public.booking_requests (id) ON DELETE CASCADE,
  rating INTEGER NOT NULL CHECK (rating >= 1 AND rating <= 5),
  comment TEXT NOT NULL DEFAULT '',
  is_hidden BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE public.favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  consumer_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  vendor_id UUID NOT NULL REFERENCES public.vendor_profiles (id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (consumer_id, vendor_id)
);

CREATE TABLE public.reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reported_by UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  target_type public.report_target NOT NULL,
  target_id UUID NOT NULL,
  reason TEXT NOT NULL,
  status public.report_status NOT NULL DEFAULT 'open',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE EXTENSION IF NOT EXISTS pg_trgm;

CREATE INDEX idx_vendor_profiles_category_city_approved
  ON public.vendor_profiles (category, city, is_approved);
CREATE INDEX idx_vendor_profiles_price ON public.vendor_profiles (price_min, price_max);
CREATE INDEX idx_vendor_profiles_business_name_trgm
  ON public.vendor_profiles USING gin (business_name gin_trgm_ops);
CREATE INDEX idx_vendor_photos_vendor ON public.vendor_photos (vendor_id, sort_order);
CREATE INDEX idx_availability_vendor_date ON public.availability (vendor_id, date);
CREATE INDEX idx_booking_requests_vendor ON public.booking_requests (vendor_id, status);
CREATE INDEX idx_booking_requests_consumer ON public.booking_requests (consumer_id);
CREATE INDEX idx_reviews_vendor ON public.reviews (vendor_id) WHERE NOT is_hidden;
CREATE INDEX idx_favorites_consumer ON public.favorites (consumer_id);
CREATE INDEX idx_reports_status ON public.reports (status);

CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles p
    WHERE p.id = auth.uid() AND p.role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.owns_vendor(p_vendor_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.vendor_profiles v
    WHERE v.id = p_vendor_id AND v.profile_id = auth.uid()
  );
$$;

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, phone, full_name, locale)
  VALUES (
    NEW.id,
    NEW.phone,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NULL),
    COALESCE(NEW.raw_user_meta_data->>'locale', 'ar')
  );
  RETURN NEW;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

CREATE OR REPLACE FUNCTION public.increment_vendor_views(p_vendor_id UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  UPDATE public.vendor_profiles
  SET view_count = view_count + 1
  WHERE id = p_vendor_id AND is_approved = true;
END;
$$;

CREATE OR REPLACE FUNCTION public.enforce_review_on_completed_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  br public.booking_requests%ROWTYPE;
BEGIN
  SELECT * INTO br FROM public.booking_requests WHERE id = NEW.booking_request_id;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'booking_request not found';
  END IF;
  IF br.status <> 'completed' THEN
    RAISE EXCEPTION 'reviews only allowed for completed bookings';
  END IF;
  IF br.consumer_id <> NEW.consumer_id THEN
    RAISE EXCEPTION 'review consumer must match booking consumer';
  END IF;
  IF br.vendor_id <> NEW.vendor_id THEN
    RAISE EXCEPTION 'review vendor must match booking vendor';
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER reviews_require_completed_booking
  BEFORE INSERT ON public.reviews
  FOR EACH ROW EXECUTE FUNCTION public.enforce_review_on_completed_booking();

-- Only admins may toggle approval / verification badges (client/API path).
-- Skips when auth.uid() is null (migrations, seed, SQL as postgres).
CREATE OR REPLACE FUNCTION public.protect_vendor_admin_flags()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'INSERT' THEN
    IF NOT public.is_admin() THEN
      NEW.is_approved := false;
      NEW.is_verified := false;
    END IF;
    RETURN NEW;
  END IF;

  IF NOT public.is_admin() THEN
    NEW.is_approved := OLD.is_approved;
    NEW.is_verified := OLD.is_verified;
  END IF;
  RETURN NEW;
END;
$$;

CREATE TRIGGER vendor_protect_admin_flags_insert
  BEFORE INSERT ON public.vendor_profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_vendor_admin_flags();

CREATE TRIGGER vendor_protect_admin_flags_update
  BEFORE UPDATE ON public.vendor_profiles
  FOR EACH ROW EXECUTE FUNCTION public.protect_vendor_admin_flags();

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.vendor_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.availability ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.booking_requests ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY profiles_select_own_or_admin ON public.profiles
  FOR SELECT USING (id = auth.uid() OR public.is_admin());
CREATE POLICY profiles_insert_own ON public.profiles
  FOR INSERT WITH CHECK (id = auth.uid());
CREATE POLICY profiles_update_own ON public.profiles
  FOR UPDATE USING (id = auth.uid()) WITH CHECK (id = auth.uid());
CREATE POLICY profiles_admin_all ON public.profiles
  FOR ALL USING (public.is_admin()) WITH CHECK (public.is_admin());

CREATE POLICY vendors_public_read_approved ON public.vendor_profiles
  FOR SELECT USING (is_approved = true OR profile_id = auth.uid() OR public.is_admin());
CREATE POLICY vendors_insert_own ON public.vendor_profiles
  FOR INSERT WITH CHECK (profile_id = auth.uid());
CREATE POLICY vendors_update_own ON public.vendor_profiles
  FOR UPDATE USING (profile_id = auth.uid() OR public.is_admin())
  WITH CHECK (profile_id = auth.uid() OR public.is_admin());
CREATE POLICY vendors_delete_own_or_admin ON public.vendor_profiles
  FOR DELETE USING (profile_id = auth.uid() OR public.is_admin());

CREATE POLICY photos_public_read ON public.vendor_photos
  FOR SELECT USING (
    public.is_admin() OR public.owns_vendor(vendor_id) OR EXISTS (
      SELECT 1 FROM public.vendor_profiles v WHERE v.id = vendor_id AND v.is_approved = true
    )
  );
CREATE POLICY photos_owner_insert ON public.vendor_photos
  FOR INSERT WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());
CREATE POLICY photos_owner_update ON public.vendor_photos
  FOR UPDATE USING (public.owns_vendor(vendor_id) OR public.is_admin())
  WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());
CREATE POLICY photos_owner_delete ON public.vendor_photos
  FOR DELETE USING (public.owns_vendor(vendor_id) OR public.is_admin());

CREATE POLICY availability_public_read ON public.availability
  FOR SELECT USING (
    public.is_admin() OR public.owns_vendor(vendor_id) OR EXISTS (
      SELECT 1 FROM public.vendor_profiles v WHERE v.id = vendor_id AND v.is_approved = true
    )
  );
CREATE POLICY availability_owner_write ON public.availability
  FOR ALL USING (public.owns_vendor(vendor_id) OR public.is_admin())
  WITH CHECK (public.owns_vendor(vendor_id) OR public.is_admin());

CREATE POLICY bookings_select_parties ON public.booking_requests
  FOR SELECT USING (
    consumer_id = auth.uid() OR public.owns_vendor(vendor_id) OR public.is_admin()
  );
CREATE POLICY bookings_insert_consumer ON public.booking_requests
  FOR INSERT WITH CHECK (consumer_id = auth.uid());
CREATE POLICY bookings_update_parties ON public.booking_requests
  FOR UPDATE USING (
    consumer_id = auth.uid() OR public.owns_vendor(vendor_id) OR public.is_admin()
  )
  WITH CHECK (
    consumer_id = auth.uid() OR public.owns_vendor(vendor_id) OR public.is_admin()
  );

CREATE POLICY reviews_public_read ON public.reviews
  FOR SELECT USING (
    (NOT is_hidden) OR consumer_id = auth.uid() OR public.owns_vendor(vendor_id) OR public.is_admin()
  );
CREATE POLICY reviews_insert_consumer ON public.reviews
  FOR INSERT WITH CHECK (consumer_id = auth.uid());
CREATE POLICY reviews_admin_update ON public.reviews
  FOR UPDATE USING (public.is_admin() OR consumer_id = auth.uid())
  WITH CHECK (public.is_admin() OR consumer_id = auth.uid());

CREATE POLICY favorites_own ON public.favorites
  FOR ALL USING (consumer_id = auth.uid()) WITH CHECK (consumer_id = auth.uid());
CREATE POLICY favorites_admin_read ON public.favorites
  FOR SELECT USING (public.is_admin());

CREATE POLICY reports_insert_auth ON public.reports
  FOR INSERT WITH CHECK (reported_by = auth.uid());
CREATE POLICY reports_select_own_or_admin ON public.reports
  FOR SELECT USING (reported_by = auth.uid() OR public.is_admin());
CREATE POLICY reports_admin_update ON public.reports
  FOR UPDATE USING (public.is_admin()) WITH CHECK (public.is_admin());

INSERT INTO storage.buckets (id, name, public)
VALUES ('vendor-photos', 'vendor-photos', true)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY vendor_photos_storage_public_read ON storage.objects
  FOR SELECT USING (bucket_id = 'vendor-photos');
CREATE POLICY vendor_photos_storage_owner_insert ON storage.objects
  FOR INSERT WITH CHECK (
    bucket_id = 'vendor-photos' AND auth.uid()::text = (storage.foldername(name))[1]
  );
CREATE POLICY vendor_photos_storage_owner_update ON storage.objects
  FOR UPDATE USING (
    bucket_id = 'vendor-photos' AND auth.uid()::text = (storage.foldername(name))[1]
  );
CREATE POLICY vendor_photos_storage_owner_delete ON storage.objects
  FOR DELETE USING (
    bucket_id = 'vendor-photos' AND auth.uid()::text = (storage.foldername(name))[1]
  );
CREATE POLICY vendor_photos_storage_admin_all ON storage.objects
  FOR ALL USING (bucket_id = 'vendor-photos' AND public.is_admin())
  WITH CHECK (bucket_id = 'vendor-photos' AND public.is_admin());

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated;
GRANT EXECUTE ON FUNCTION public.increment_vendor_views(UUID) TO anon, authenticated;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.owns_vendor(UUID) TO authenticated;
