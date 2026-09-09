-- Retire the beauty vendor vertical from product surfaces.
-- Keep the Postgres enum value so dumps and leftover rows stay valid.
-- Recategorize live listings to other. Flutter Discover / Favorites also
-- exclude leftover beauty rows until this UPDATE is applied on Dahr LY.

UPDATE public.vendor_profiles
SET category = 'other'
WHERE category = 'beauty';
