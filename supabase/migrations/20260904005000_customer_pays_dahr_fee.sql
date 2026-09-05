-- Customer (couple) pays Dahr the 10% platform fee by online bank transfer.
-- Git-only: do NOT `db push` this onto live Dahr LY from the app PR.
-- Syber applies live. Reuses quoted_amount_lyd / commission_amount_lyd /
-- commission_status and admin RPC set_booking_commission_status.
-- Couples still cannot UPDATE booking_requests or set commission_status.

COMMENT ON COLUMN public.booking_requests.quoted_amount_lyd IS
  'Vendor quote in LYD, required when accepting. Couple settles this with the vendor off-platform (often WhatsApp).';
COMMENT ON COLUMN public.booking_requests.commission_rate IS
  'Dahr platform-fee rate recorded on the booking (default 10%).';
COMMENT ON COLUMN public.booking_requests.commission_amount_lyd IS
  'ROUND(quoted_amount_lyd * commission_rate, 2). Paid by the couple to Dahr by bank transfer, not by the vendor.';
COMMENT ON COLUMN public.booking_requests.commission_status IS
  'unpaid when a quote exists; admin sets paid or waived after the couple''s bank transfer. Null until accepted. Couples cannot set this.';
COMMENT ON COLUMN public.booking_requests.commission_paid_at IS
  'When an admin marked the couple''s platform fee as paid.';

-- Operator bank details. Empty placeholders only — no real account numbers.
CREATE TABLE public.platform_settings (
  id TEXT PRIMARY KEY DEFAULT 'default' CHECK (id = 'default'),
  bank_name TEXT NOT NULL DEFAULT '',
  account_holder TEXT NOT NULL DEFAULT '',
  account_number TEXT NOT NULL DEFAULT '',
  bank_note TEXT NOT NULL DEFAULT '',
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE public.platform_settings IS
  'Singleton operator settings. Bank fields start empty; Mohammed pastes real Dahr details in admin. Do not invent a Libyan account number in git.';

INSERT INTO public.platform_settings (id)
VALUES ('default')
ON CONFLICT (id) DO NOTHING;

ALTER TABLE public.platform_settings ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.platform_settings FROM PUBLIC, anon;
GRANT SELECT, UPDATE ON TABLE public.platform_settings TO authenticated;

CREATE POLICY platform_settings_select_authenticated
  ON public.platform_settings
  FOR SELECT
  TO authenticated
  USING (true);

CREATE POLICY platform_settings_update_admin
  ON public.platform_settings
  FOR UPDATE
  TO authenticated
  USING (public.is_admin())
  WITH CHECK (public.is_admin());

-- Couple can record a transfer reference without touching commission_status.
CREATE TABLE public.commission_transfer_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  booking_id UUID NOT NULL REFERENCES public.booking_requests (id) ON DELETE CASCADE,
  consumer_id UUID NOT NULL REFERENCES public.profiles (id) ON DELETE CASCADE,
  reference_note TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT commission_transfer_note_len CHECK (
    char_length(btrim(reference_note)) BETWEEN 1 AND 500
  )
);

COMMENT ON TABLE public.commission_transfer_notes IS
  'Couple-submitted bank-transfer reference. Insert-only. Does not change commission_status; admin still confirms paid/waived.';

CREATE INDEX idx_commission_transfer_notes_booking
  ON public.commission_transfer_notes (booking_id, created_at DESC);

ALTER TABLE public.commission_transfer_notes ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON TABLE public.commission_transfer_notes FROM PUBLIC, anon;
GRANT SELECT, INSERT ON TABLE public.commission_transfer_notes TO authenticated;

CREATE POLICY commission_transfer_notes_select_own_or_admin
  ON public.commission_transfer_notes
  FOR SELECT
  TO authenticated
  USING (
    consumer_id = auth.uid()
    OR public.is_admin()
  );

CREATE POLICY commission_transfer_notes_insert_own_unpaid
  ON public.commission_transfer_notes
  FOR INSERT
  TO authenticated
  WITH CHECK (
    consumer_id = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.booking_requests b
      WHERE b.id = booking_id
        AND b.consumer_id = auth.uid()
        AND b.quoted_amount_lyd IS NOT NULL
        AND b.commission_status = 'unpaid'
    )
  );
