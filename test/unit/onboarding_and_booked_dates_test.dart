import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _between(String src, String start, String end) {
  final from = src.indexOf(start);
  expect(from, greaterThanOrEqualTo(0), reason: 'missing $start');
  final to = src.indexOf(end, from + 1);
  expect(to, greaterThan(from), reason: 'missing $end after $start');
  return src.substring(from, to);
}

void main() {
  late String authProvider;
  late String bookingProvider;
  late String vendorProvider;
  late String bookingRequestScreen;

  setUpAll(() {
    authProvider =
        File('lib/core/providers/auth_provider.dart').readAsStringSync();
    bookingProvider =
        File('lib/features/booking/providers/booking_provider.dart')
            .readAsStringSync();
    vendorProvider =
        File('lib/features/vendor_profile/providers/vendor_provider.dart')
            .readAsStringSync();
    bookingRequestScreen =
        File('lib/features/booking/screens/booking_request_screen.dart')
            .readAsStringSync();
  });

  group('onboarding advances past role select', () {
    test('setRole leaves needsRole so profile setup is reachable', () {
      // profiles.role defaults to consumer, so re-reading the row cannot tell
      // "picked consumer" from "never picked" and keeps reporting needsRole.
      // Without this step the router bounces profile setup back to role select.
      final setRole = _between(
        authProvider,
        'Future<void> setRole(',
        'Future<void> completeProfile(',
      );
      expect(setRole.contains('AuthFlowStatus.needsProfile'), isTrue);
    });

    test('every profiles write fails closed on zero rows', () {
      final updateLocale = _between(
        authProvider,
        'Future<void> updateLocale(',
        'Future<void> signOut(',
      );
      expect(updateLocale.contains('requireMutatedRows'), isTrue);
    });
  });

  group('booked dates stay trustworthy', () {
    test('booking screen never falls back to an empty booked set', () {
      expect(bookingRequestScreen.contains('?? <String>{}'), isFalse);
    });

    test('availability writes invalidate the couple-facing booked dates', () {
      expect(
        vendorProvider.contains('ref.invalidate(vendorBookedDatesProvider)'),
        isTrue,
        reason: 'vendor availability upsert must refresh booked dates',
      );
      expect(
        bookingProvider.contains('ref.invalidate(vendorBookedDatesProvider)'),
        isTrue,
        reason: 'accepting a booking blocks the date and must refresh it',
      );
    });
  });
}
