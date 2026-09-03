import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('revoke_anon_definer_rpcs drops existing split policies before create', () {
    final sql = File(
      'supabase/migrations/20260903120000_revoke_anon_definer_rpcs.sql',
    ).readAsStringSync();
    expect(
      sql,
      contains('DROP POLICY IF EXISTS vendors_select_approved ON public.vendor_profiles'),
    );
    expect(
      sql.indexOf('DROP POLICY IF EXISTS vendors_select_approved'),
      lessThan(sql.indexOf('CREATE POLICY vendors_select_approved')),
    );
    expect(
      sql,
      contains(
        'DROP POLICY IF EXISTS photos_select_approved_vendor ON public.vendor_photos',
      ),
    );
    expect(
      sql,
      contains(
        'DROP POLICY IF EXISTS availability_select_approved_vendor ON public.availability',
      ),
    );
  });
}
