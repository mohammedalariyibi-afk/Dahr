-- Seed data for Dahr local / demo environments ONLY.
-- Do not run against live Dahr LY / production. Known emails
-- (admin@dahr.ly, couple@dahr.ly) and password123 are for Inbucket.
-- Creates demo auth users, approved vendors across Tripoli & Benghazi,
-- one pending vendor for the admin approve flow, photos, availability,
-- completed bookings + reviews, sample reports, and one admin.

-- Fixed UUIDs for reproducibility
-- Admin:     a0000000-0000-4000-8000-000000000001
-- Consumer:  a0000000-0000-4000-8000-000000000002
-- Vendors:   b0000000-0000-4000-8000-0000000000xx

-- Supabase puts pgcrypto in the extensions schema
CREATE EXTENSION IF NOT EXISTS pgcrypto WITH SCHEMA extensions;

-- Helper: insert auth user if missing (local/dev only)
CREATE OR REPLACE FUNCTION public._seed_user(
  p_id UUID,
  p_email TEXT,
  p_phone TEXT DEFAULT NULL,
  p_name TEXT DEFAULT NULL
) RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, auth, extensions
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM auth.users WHERE id = p_id) THEN
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      phone,
      encrypted_password,
      email_confirmed_at,
      phone_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      -- GoTrue scans these token columns as non-null strings; seeding them as
      -- '' (not NULL) keeps Email OTP login working for demo users.
      confirmation_token,
      recovery_token,
      email_change,
      email_change_token_new
    ) VALUES (
      p_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      p_email,
      p_phone,
      extensions.crypt('password123', extensions.gen_salt('bf')),
      now(),
      CASE WHEN p_phone IS NULL THEN NULL ELSE now() END,
      '{"provider":"email","providers":["email"]}'::jsonb,
      jsonb_build_object('full_name', p_name, 'locale', 'ar'),
      now(),
      now(),
      '',
      '',
      '',
      ''
    );
  END IF;
END;
$$;

SELECT public._seed_user(
  'a0000000-0000-4000-8000-000000000001',
  'admin@dahr.ly',
  NULL,
  'Dahr Admin'
);
SELECT public._seed_user(
  'a0000000-0000-4000-8000-000000000002',
  'couple@dahr.ly',
  '+218912000001',
  'سارة وأحمد'
);

SELECT public._seed_user('b0000000-0000-4000-8000-000000000001', 'venues1@dahr.ly', '+218912100001', 'قاعة النور');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000002', 'venues2@dahr.ly', '+218912100002', 'قاعة البحر');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000003', 'photo1@dahr.ly', '+218912100003', 'استوديو لحظة');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000004', 'photo2@dahr.ly', '+218912100004', 'عدسة بنغازي');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000005', 'cater1@dahr.ly', '+218912100005', 'مطبخ الأصيل');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000006', 'dress1@dahr.ly', '+218912100006', 'فستان العروس');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000007', 'beauty1@dahr.ly', '+218912100007', 'حناء ملكية');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000008', 'beauty2@dahr.ly', '+218912100008', 'ميكب نور');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000009', 'music1@dahr.ly', '+218912100009', 'دي جي طرابلس');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000010', 'cars1@dahr.ly', '+218912100010', 'سيارات الزفاف');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000011', 'decor1@dahr.ly', '+218912100011', 'ديكور الأحلام');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000012', 'cater2@dahr.ly', '+218912100012', 'ولائم الشرق');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000013', 'music2@dahr.ly', '+218912100013', 'فرقة الأندلس');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000014', 'other1@dahr.ly', '+218912100014', 'خدمات المناسبات');
SELECT public._seed_user('b0000000-0000-4000-8000-000000000015', 'pending@dahr.ly', '+218912100015', 'قاعة الياسمين');

-- Promote admin + consumer profiles
UPDATE public.profiles
SET role = 'admin', full_name = 'Dahr Admin', locale = 'ar'
WHERE id = 'a0000000-0000-4000-8000-000000000001';

UPDATE public.profiles
SET
  role = 'consumer',
  full_name = 'سارة وأحمد',
  city = 'tripoli',
  wedding_date = CURRENT_DATE + 120,
  locale = 'ar',
  phone = '+218912000001'
WHERE id = 'a0000000-0000-4000-8000-000000000002';

UPDATE public.profiles SET role = 'vendor', city = 'tripoli', locale = 'ar'
WHERE id IN (
  'b0000000-0000-4000-8000-000000000001',
  'b0000000-0000-4000-8000-000000000003',
  'b0000000-0000-4000-8000-000000000005',
  'b0000000-0000-4000-8000-000000000006',
  'b0000000-0000-4000-8000-000000000007',
  'b0000000-0000-4000-8000-000000000009',
  'b0000000-0000-4000-8000-000000000011',
  'b0000000-0000-4000-8000-000000000014',
  'b0000000-0000-4000-8000-000000000015'
);

UPDATE public.profiles SET role = 'vendor', city = 'benghazi', locale = 'ar'
WHERE id IN (
  'b0000000-0000-4000-8000-000000000002',
  'b0000000-0000-4000-8000-000000000004',
  'b0000000-0000-4000-8000-000000000008',
  'b0000000-0000-4000-8000-000000000010',
  'b0000000-0000-4000-8000-000000000012',
  'b0000000-0000-4000-8000-000000000013'
);

-- Vendor listings (approved for demo)
INSERT INTO public.vendor_profiles (
  id, profile_id, business_name, category, city, description,
  price_min, price_max, whatsapp_number, services, is_verified, is_approved, view_count
) VALUES
(
  'c0000000-0000-4000-8000-000000000001',
  'b0000000-0000-4000-8000-000000000001',
  'قاعة النور',
  'venues',
  'tripoli',
  'قاعة أفراح واسعة في طرابلس مع إضاءة حديثة وخدمة ضيافة.',
  5000, 15000, '218912100001',
  ARRAY['قاعة داخلية', 'مواقف سيارات', 'تزيين أساسي'],
  true, true, 42
),
(
  'c0000000-0000-4000-8000-000000000002',
  'b0000000-0000-4000-8000-000000000002',
  'قاعة البحر المتوسط',
  'venues',
  'benghazi',
  'قاعة بإطلالة ساحلية في بنغازي مناسبة للحفلات الكبيرة.',
  4000, 12000, '218912100002',
  ARRAY['إطلالة بحر', 'نظام صوت', 'مطبخ'],
  true, true, 31
),
(
  'c0000000-0000-4000-8000-000000000003',
  'b0000000-0000-4000-8000-000000000003',
  'استوديو لحظة',
  'photography',
  'tripoli',
  'تصوير فوتوغرافي وسينمائي للزفاف بخبرة أكثر من 8 سنوات.',
  800, 3500, '218912100003',
  ARRAY['تصوير فوتو', 'فيديو سينمائي', 'ألبوم'],
  true, true, 55
),
(
  'c0000000-0000-4000-8000-000000000004',
  'b0000000-0000-4000-8000-000000000004',
  'عدسة بنغازي',
  'photography',
  'benghazi',
  'جلسات تصوير خارجية وداخلية بأسعار مرنة.',
  600, 2500, '218912100004',
  ARRAY['جلسة خطوبة', 'يوم الزفاف'],
  false, true, 18
),
(
  'c0000000-0000-4000-8000-000000000005',
  'b0000000-0000-4000-8000-000000000005',
  'مطبخ الأصيل',
  'catering',
  'tripoli',
  'بوفيه ليبي وعربي للأفراح مع خدمة طاولات.',
  25, 80, '218912100005',
  ARRAY['بوفيه مفتوح', 'مشروبات', 'حلويات'],
  true, true, 67
),
(
  'c0000000-0000-4000-8000-000000000006',
  'b0000000-0000-4000-8000-000000000006',
  'فستان العروس',
  'dresses',
  'tripoli',
  'تأجير وبيع فساتين زفاف وبدلات رجالية.',
  200, 2000, '218912100006',
  ARRAY['فساتين زفاف', 'بدلات', 'تعديلات'],
  false, true, 22
),
(
  'c0000000-0000-4000-8000-000000000007',
  'b0000000-0000-4000-8000-000000000007',
  'حناء ملكية',
  'beauty',
  'tripoli',
  'حناء تقليدية وعصرية مع مكياج عروس.',
  150, 800, '218912100007',
  ARRAY['حناء', 'مكياج', 'تسريحة'],
  true, true, 40
),
(
  'c0000000-0000-4000-8000-000000000008',
  'b0000000-0000-4000-8000-000000000008',
  'ميكب نور',
  'beauty',
  'benghazi',
  'مكياج احترافي للمناسبات في بنغازي.',
  100, 600, '218912100008',
  ARRAY['مكياج عروس', 'مكياج ضيوف'],
  false, true, 15
),
(
  'c0000000-0000-4000-8000-000000000009',
  'b0000000-0000-4000-8000-000000000009',
  'دي جي طرابلس',
  'music',
  'tripoli',
  'دي جي مع إضاءة وميكروفونات للمناسبات.',
  400, 1500, '218912100009',
  ARRAY['دي جي', 'إضاءة', 'نظام صوت'],
  true, true, 28
),
(
  'c0000000-0000-4000-8000-000000000010',
  'b0000000-0000-4000-8000-000000000010',
  'سيارات الزفاف',
  'cars',
  'benghazi',
  'تأجير سيارات فاخرة ومزينة للزفاف.',
  300, 1200, '218912100010',
  ARRAY['سيارة عروس', 'تزيين', 'سائق'],
  false, true, 19
),
(
  'c0000000-0000-4000-8000-000000000011',
  'b0000000-0000-4000-8000-000000000011',
  'ديكور الأحلام',
  'decor',
  'tripoli',
  'تنسيق ورود ومنصات وتصميم قاعات.',
  1000, 7000, '218912100011',
  ARRAY['ورود', 'منصة', 'طاولات'],
  true, true, 36
),
(
  'c0000000-0000-4000-8000-000000000012',
  'b0000000-0000-4000-8000-000000000012',
  'ولائم الشرق',
  'catering',
  'benghazi',
  'ضيافة كاملة مع قائمة مخصصة حسب عدد الضيوف.',
  20, 70, '218912100012',
  ARRAY['وجبات فردية', 'بوفيه', 'قهوة عربية'],
  false, true, 24
),
(
  'c0000000-0000-4000-8000-000000000013',
  'b0000000-0000-4000-8000-000000000013',
  'فرقة الأندلس',
  'music',
  'benghazi',
  'فرقة موسيقية حية للزفاف والمناسبات.',
  800, 3000, '218912100013',
  ARRAY['موسيقى حية', 'غناء'],
  true, true, 21
),
(
  'c0000000-0000-4000-8000-000000000014',
  'b0000000-0000-4000-8000-000000000014',
  'خدمات المناسبات',
  'other',
  'tripoli',
  'تنسيق عام وخدمات إضافية ليوم الزفاف.',
  200, 2000, '218912100014',
  ARRAY['منسق حفل', 'استقبال'],
  false, true, 12
),
(
  'c0000000-0000-4000-8000-000000000015',
  'b0000000-0000-4000-8000-000000000015',
  'قاعة الياسمين',
  'venues',
  'tripoli',
  'قاعة أفراح جديدة في طرابلس بانتظار موافقة الإدارة.',
  3500, 9000, '218912100015',
  ARRAY['قاعة داخلية', 'تزيين'],
  false, false, 3
)
ON CONFLICT (id) DO NOTHING;

-- Placeholder photos (Unsplash) — idempotent
INSERT INTO public.vendor_photos (vendor_id, storage_url, sort_order)
SELECT v.vendor_id, v.storage_url, v.sort_order
FROM (VALUES
  ('c0000000-0000-4000-8000-000000000001'::uuid, 'https://images.unsplash.com/photo-1519167758481-83f29da8c2c2?w=800', 0),
  ('c0000000-0000-4000-8000-000000000001'::uuid, 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?w=800', 1),
  ('c0000000-0000-4000-8000-000000000002'::uuid, 'https://images.unsplash.com/photo-1478144592103-25e218a04891?w=800', 0),
  ('c0000000-0000-4000-8000-000000000003'::uuid, 'https://images.unsplash.com/photo-1511285560929-80b456fe3129?w=800', 0),
  ('c0000000-0000-4000-8000-000000000003'::uuid, 'https://images.unsplash.com/photo-1606216794074-735e91aa2c92?w=800', 1),
  ('c0000000-0000-4000-8000-000000000004'::uuid, 'https://images.unsplash.com/photo-1520854221256-17451cc331bf?w=800', 0),
  ('c0000000-0000-4000-8000-000000000005'::uuid, 'https://images.unsplash.com/photo-1555244162-803834f70033?w=800', 0),
  ('c0000000-0000-4000-8000-000000000006'::uuid, 'https://images.unsplash.com/photo-1594552072238-b8a33785b401?w=800', 0),
  ('c0000000-0000-4000-8000-000000000007'::uuid, 'https://images.unsplash.com/photo-1487412947147-5cebf100ffc2?w=800', 0),
  ('c0000000-0000-4000-8000-000000000008'::uuid, 'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?w=800', 0),
  ('c0000000-0000-4000-8000-000000000009'::uuid, 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800', 0),
  ('c0000000-0000-4000-8000-000000000010'::uuid, 'https://images.unsplash.com/photo-1492144534655-ae79c964c9d7?w=800', 0),
  ('c0000000-0000-4000-8000-000000000011'::uuid, 'https://images.unsplash.com/photo-1519225421980-715cb0215aed?w=800', 0),
  ('c0000000-0000-4000-8000-000000000012'::uuid, 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800', 0),
  ('c0000000-0000-4000-8000-000000000013'::uuid, 'https://images.unsplash.com/photo-1511379938547-c1f69419868d?w=800', 0),
  ('c0000000-0000-4000-8000-000000000014'::uuid, 'https://images.unsplash.com/photo-1465495976277-4387d4b0b4c6?w=800', 0),
  ('c0000000-0000-4000-8000-000000000015'::uuid, 'https://images.unsplash.com/photo-1519741497674-611481863552?w=800', 0)
) AS v(vendor_id, storage_url, sort_order)
WHERE NOT EXISTS (
  SELECT 1 FROM public.vendor_photos p
  WHERE p.vendor_id = v.vendor_id AND p.storage_url = v.storage_url
);

-- Sample booked dates
INSERT INTO public.availability (vendor_id, date, status) VALUES
('c0000000-0000-4000-8000-000000000001', CURRENT_DATE + 30, 'booked'),
('c0000000-0000-4000-8000-000000000001', CURRENT_DATE + 45, 'booked'),
('c0000000-0000-4000-8000-000000000003', CURRENT_DATE + 20, 'booked'),
('c0000000-0000-4000-8000-000000000005', CURRENT_DATE + 35, 'booked')
ON CONFLICT DO NOTHING;

-- Completed + accepted bookings for demo (10% commission tracked, unpaid until admin marks paid)
INSERT INTO public.booking_requests (
  id, vendor_id, consumer_id, event_date, guest_count, message, status,
  quoted_amount_lyd
) VALUES (
  'd0000000-0000-4000-8000-000000000001',
  'c0000000-0000-4000-8000-000000000003',
  'a0000000-0000-4000-8000-000000000002',
  CURRENT_DATE - 14,
  180,
  'نحتاج تصوير كامل ليوم الزفاف.',
  'completed',
  3500
),
(
  'd0000000-0000-4000-8000-000000000002',
  'c0000000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000002',
  CURRENT_DATE + 60,
  250,
  'حجز القاعة مع التزيين الأساسي.',
  'pending',
  NULL
),
(
  'd0000000-0000-4000-8000-000000000003',
  'c0000000-0000-4000-8000-000000000005',
  'a0000000-0000-4000-8000-000000000002',
  CURRENT_DATE + 40,
  200,
  'ضيافة ليوم الزفاف.',
  'accepted',
  4500
)
ON CONFLICT (id) DO NOTHING;

-- accept_booking_request marks the date booked in the same transaction; these
-- rows are inserted directly, so the demo calendar needs the same entries.
INSERT INTO public.availability (vendor_id, date, status)
SELECT b.vendor_id, b.event_date, 'booked'::public.availability_status
FROM public.booking_requests b
WHERE b.status IN (
  'accepted'::public.booking_status,
  'completed'::public.booking_status
)
ON CONFLICT (vendor_id, date)
DO UPDATE SET status = 'booked'::public.availability_status;

INSERT INTO public.reviews (
  vendor_id, consumer_id, booking_request_id, rating, comment
) VALUES (
  'c0000000-0000-4000-8000-000000000003',
  'a0000000-0000-4000-8000-000000000002',
  'd0000000-0000-4000-8000-000000000001',
  5,
  'تصوير رائع وخدمة محترفة. أنصح بهم بشدة.'
)
ON CONFLICT DO NOTHING;

-- Sample moderation queue: one vendor report + one review report
INSERT INTO public.reports (id, reported_by, target_type, target_id, reason, status)
VALUES (
  'f0000000-0000-4000-8000-000000000001',
  'a0000000-0000-4000-8000-000000000002',
  'vendor',
  'c0000000-0000-4000-8000-000000000010',
  'Listed photos look unrelated to the cars offered.',
  'open'
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.reports (id, reported_by, target_type, target_id, reason, status)
SELECT
  'f0000000-0000-4000-8000-000000000002',
  'a0000000-0000-4000-8000-000000000002',
  'review',
  r.id,
  'Review looks copied / not a real customer.',
  'open'
FROM public.reviews r
WHERE r.booking_request_id = 'd0000000-0000-4000-8000-000000000001'
  AND NOT EXISTS (
    SELECT 1 FROM public.reports x
    WHERE x.id = 'f0000000-0000-4000-8000-000000000002'
  );

-- Auth identities so email OTP / password can resolve seeded users locally
INSERT INTO auth.identities (
  id,
  user_id,
  identity_data,
  provider,
  provider_id,
  last_sign_in_at,
  created_at,
  updated_at
)
SELECT
  u.id,
  u.id,
  jsonb_build_object('sub', u.id::text, 'email', u.email),
  'email',
  u.id::text,
  now(),
  now(),
  now()
FROM auth.users u
WHERE u.email LIKE '%@dahr.ly'
  AND NOT EXISTS (
    SELECT 1 FROM auth.identities i WHERE i.user_id = u.id AND i.provider = 'email'
  );

DROP FUNCTION IF EXISTS public._seed_user(UUID, TEXT, TEXT, TEXT);
