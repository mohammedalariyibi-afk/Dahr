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
      'supabase/migrations/20260903230000_booking_integrity_guards.sql',
    ).readAsStringSync();
  });

  test('new migration sits after review-scope and is uniquely named', () {
    expect(
      migrationNames,
      contains('20260903210000_scope_booking_updates_and_insert_only_reviews.sql'),
    );
    expect(
      migrationNames,
      contains('20260903230000_booking_integrity_guards.sql'),
    );
    expect(
      migrationNames.indexOf('20260903230000_booking_integrity_guards.sql'),
      greaterThan(
        migrationNames.indexOf(
          '20260903210000_scope_booking_updates_and_insert_only_reviews.sql',
        ),
      ),
    );
    expect(
      migrationNames.where((n) => n.contains('booking_integrity_guards')),
      hasLength(1),
    );
  });

  test('forces consumer inserts to pending against an approved vendor', () {
    expect(sql, contains("RAISE EXCEPTION 'booking_must_be_pending'"));
    expect(sql, contains("RAISE EXCEPTION 'vendor_not_approved'"));
    expect(sql, contains('NEW.status IS DISTINCT FROM \'pending\''));
    expect(sql, contains('v.is_approved = true'));
  });

  test('locks booking identity and enforces the vendor status machine', () {
    expect(sql, contains('NEW.consumer_id := OLD.consumer_id'));
    expect(sql, contains('NEW.vendor_id := OLD.vendor_id'));
    expect(sql, contains('NEW.event_date := OLD.event_date'));
    expect(sql, contains("RAISE EXCEPTION 'invalid_booking_transition'"));
    expect(
      sql,
      contains(
        "OLD.status = 'accepted'::public.booking_status\n     AND NEW.status = 'completed'::public.booking_status",
      ),
    );
  });

  test('one held booking per vendor date plus accept-time calendar mark', () {
    expect(sql, contains('booking_requests_one_held_date'));
    expect(sql, contains("RAISE EXCEPTION 'date_unavailable'"));
    expect(sql, contains('BEFORE INSERT OR UPDATE ON public.booking_requests'));
    expect(
      sql,
      contains("VALUES (rec.vendor_id, rec.event_date, 'booked'::public.availability_status)"),
    );
  });

  test('review insert cannot self-hide; view_count only via increment RPC', () {
    expect(sql, contains('NEW.is_hidden := false'));
    expect(sql, contains("set_config('dahr.allow_view_increment', 'on', true)"));
    expect(sql, contains('NEW.view_count := OLD.view_count'));
  });

  test('availability cannot free a date with an accepted booking', () {
    expect(sql, contains('protect_availability_held_dates'));
    expect(sql, contains("RAISE EXCEPTION 'date_has_accepted_booking'"));
    expect(
      sql,
      contains(
        'REVOKE ALL ON FUNCTION public.protect_availability_held_dates() FROM PUBLIC, anon, authenticated',
      ),
    );
  });

  test('new helpers stay trigger-only, not anon RPCs', () {
    expect(
      sql,
      isNot(contains('GRANT EXECUTE ON FUNCTION public.reject_booking_if_date_booked() TO anon')),
    );
    expect(
      sql,
      isNot(
        contains(
          'GRANT EXECUTE ON FUNCTION public.protect_availability_held_dates() TO authenticated',
        ),
      ),
    );
  });
}
