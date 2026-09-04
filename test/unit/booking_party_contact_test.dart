import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migration = '20260904120000_booking_party_contact.sql';

void main() {
  late String sql;
  late List<String> migrationNames;

  setUpAll(() {
    migrationNames = Directory('supabase/migrations')
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    sql = File('supabase/migrations/$_migration').readAsStringSync();
  });

  test('sits after guest-read and is unique', () {
    expect(migrationNames, contains(_migration));
    expect(migrationNames.last, _migration);
    expect(
      migrationNames.indexOf(_migration),
      greaterThan(
        migrationNames.indexOf(
          '20260904010000_guest_read_policies_without_helper_execute.sql',
        ),
      ),
    );
    expect(
      migrationNames.where((n) => n.contains('booking_party_contact')),
      hasLength(1),
    );
  });

  test('definer view is authenticated-only and does not leak to guests', () {
    expect(sql, contains('CREATE OR REPLACE FUNCTION private.booking_party_contact_rows()'));
    expect(sql, contains('RETURNS TABLE(id uuid, full_name text, phone text)'));
    expect(sql, contains('SET search_path = \'\''));
    expect(sql, contains('public.owns_vendor(b.vendor_id)'));
    expect(sql, contains('CREATE OR REPLACE VIEW public.booking_party_contact'));
    expect(
      sql,
      contains('WITH (security_invoker = true, security_barrier = true)'),
    );
    expect(
      sql,
      contains(
        'GRANT EXECUTE ON FUNCTION private.booking_party_contact_rows() TO authenticated, service_role',
      ),
    );
    expect(
      sql,
      contains(
        'GRANT SELECT ON public.booking_party_contact TO authenticated, service_role',
      ),
    );
    expect(sql, isNot(contains('TO anon')));
    expect(sql, isNot(contains('GRANT SELECT ON public.booking_party_contact TO anon')));
  });

  test('does not re-grant helpers to anon or touch storage', () {
    expect(sql, isNot(contains('GRANT EXECUTE ON FUNCTION public.is_admin')));
    expect(sql, isNot(contains('GRANT EXECUTE ON FUNCTION public.owns_vendor')));
    expect(sql, isNot(contains('storage.objects')));
    expect(sql, isNot(contains('vendor-photos')));
  });
}
