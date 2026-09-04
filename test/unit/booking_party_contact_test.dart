import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking.dart';
import 'package:dahr/features/booking/providers/booking_provider.dart';

const _migration = '20260904120000_booking_party_contact.sql';

BookingRequest _booking(String consumerId) => BookingRequest(
      id: 'b1',
      vendorId: 'v1',
      consumerId: consumerId,
      eventDate: DateTime(2030, 6, 15),
    );

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

  group('vendor inbox fails soft when party contact is missing', () {
    test('attachBookingPartyContacts catches lookup errors', () {
      final src = File('lib/features/booking/providers/booking_provider.dart')
          .readAsStringSync();
      final attach = src.substring(
        src.indexOf('Future<List<BookingRequest>> attachBookingPartyContacts'),
        src.indexOf('List<BookingRequest> applyBookingPartyContactRows'),
      );
      expect(attach, contains('try {'));
      expect(attach, contains('catch'));
      expect(attach, contains('return bookings'));
      expect(
        File('lib/features/vendor_profile/screens/vendor_inbox_screen.dart')
            .readAsStringSync(),
        contains('coupleContactUnknown'),
      );
    });

    test('isPartyContactLookupFailure matches PostgREST schema misses', () {
      expect(
        isPartyContactLookupFailure(
          Exception(
            "PostgrestException(message: Could not find the table "
            "'public.booking_party_contact' in the schema cache, code: PGRST205)",
          ),
        ),
        isTrue,
      );
      expect(
        isPartyContactLookupFailure(
          Exception('relation "booking_party_contact" does not exist (42P01)'),
        ),
        isTrue,
      );
      expect(
        isPartyContactLookupFailure(StateError('write_rejected')),
        isFalse,
      );
    });

    test('applyBookingPartyContactRows fills name and phone', () {
      final merged = applyBookingPartyContactRows(
        [_booking('c1'), _booking('c2')],
        [
          {'id': 'c1', 'full_name': 'Salma', 'phone': '+218912345678'},
        ],
      );
      expect(merged[0].consumerName, 'Salma');
      expect(merged[0].hasCoupleWhatsApp, isTrue);
      expect(merged[1].consumerName, isNull);
      expect(merged[1].hasCoupleWhatsApp, isFalse);
    });

    test('empty contact rows leave bookings usable without name or phone', () {
      final merged = applyBookingPartyContactRows([_booking('c1')], const []);
      expect(merged.single.consumerName, isNull);
      expect(merged.single.consumerPhone, isNull);
      expect(merged.single.hasCoupleWhatsApp, isFalse);
    });
  });
}
