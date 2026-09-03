import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;
  late List<String> migrationNames;

  setUpAll(() {
    final dir = Directory('supabase/migrations');
    migrationNames = dir
        .listSync()
        .whereType<File>()
        .map((f) => f.uri.pathSegments.last)
        .toList()
      ..sort();
    sql = File(
      'supabase/migrations/20260903184000_overnight_security_hardening.sql',
    ).readAsStringSync();
  });

  test('new migration sits after delete_own_account and is uniquely named', () {
    expect(
      migrationNames,
      contains('20260903140000_delete_own_account.sql'),
    );
    expect(
      migrationNames,
      contains('20260903184000_overnight_security_hardening.sql'),
    );
    expect(
      migrationNames.indexOf('20260903184000_overnight_security_hardening.sql'),
      greaterThan(migrationNames.indexOf('20260903140000_delete_own_account.sql')),
    );
    expect(
      migrationNames.where((n) => n.contains('overnight_security_hardening')),
      hasLength(1),
    );
    expect(
      migrationNames.where((n) => n.contains('init_schema')),
      hasLength(1),
    );
  });

  test('revokes reject_booking_if_date_booked from PUBLIC/anon/authenticated', () {
    expect(sql, contains('CREATE OR REPLACE FUNCTION public.reject_booking_if_date_booked()'));
    expect(sql, contains('RETURNS trigger'));
    expect(sql, contains("RAISE EXCEPTION 'date_unavailable'"));
    expect(sql, contains('CREATE TRIGGER booking_reject_if_date_booked'));
    expect(sql, contains('BEFORE INSERT ON public.booking_requests'));
    expect(
      sql,
      contains('REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM PUBLIC'),
    );
    expect(
      sql,
      contains('REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM anon'),
    );
    expect(
      sql,
      contains(
        'REVOKE ALL ON FUNCTION public.reject_booking_if_date_booked() FROM authenticated',
      ),
    );
    expect(
      sql,
      isNot(contains('GRANT EXECUTE ON FUNCTION public.reject_booking_if_date_booked()')),
    );
  });

  test('does not re-grant is_admin or owns_vendor to anon', () {
    expect(sql, contains('REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon'));
    expect(
      sql,
      contains('REVOKE ALL ON FUNCTION public.owns_vendor(uuid) FROM PUBLIC, anon'),
    );
    expect(sql, contains('GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated'));
    expect(
      sql,
      contains('GRANT EXECUTE ON FUNCTION public.owns_vendor(uuid) TO authenticated'),
    );
    expect(sql, isNot(contains('GRANT EXECUTE ON FUNCTION public.is_admin() TO anon')));
    expect(
      sql,
      isNot(contains('GRANT EXECUTE ON FUNCTION public.owns_vendor(uuid) TO anon')),
    );
    expect(sql.toLowerCase(), isNot(contains('grant_rls_helpers_to_anon')));
  });

  test('replaces profile_public with security_invoker view of id, full_name', () {
    expect(sql, contains('DROP VIEW IF EXISTS public.profile_public'));
    expect(sql, contains('WITH (security_invoker = true)'));
    expect(sql, contains('SELECT id, full_name'));
    expect(sql, isNot(contains('security_barrier')));
    expect(sql, contains('GRANT SELECT ON public.profile_public TO anon, authenticated'));
  });

  test('adds profiles_select_public_names for reviews, vendors, counterparties', () {
    expect(sql, contains('CREATE POLICY profiles_select_public_names ON public.profiles'));
    expect(sql, contains('FROM public.reviews r'));
    expect(sql, contains('FROM public.vendor_profiles v'));
    expect(sql, contains('FROM public.booking_requests b'));
    expect(sql, contains('r.is_hidden = false'));
    expect(sql, contains('v.is_approved = true'));
  });
}
