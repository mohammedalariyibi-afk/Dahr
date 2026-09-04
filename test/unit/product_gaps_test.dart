import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking.dart';
import 'package:dahr/core/models/booking_select.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/review.dart';
import 'package:dahr/core/routing/auth_redirect.dart';
import 'package:dahr/core/providers/auth_provider.dart';

void main() {
  group('couple contact on a booking', () {
    test('withConsumerContact fills name and phone and leaves money alone', () {
      final booking = BookingRequest(
        id: 'b1',
        vendorId: 'v1',
        consumerId: 'c1',
        eventDate: DateTime(2030, 6, 15),
        quotedAmountLyd: 1000,
        commissionAmountLyd: 100,
        commissionStatus: CommissionStatus.unpaid,
      );
      final named = booking.withConsumerContact(
        name: 'Salma',
        phone: '+218912345678',
      );
      expect(named.consumerName, 'Salma');
      expect(named.consumerPhone, '+218912345678');
      expect(named.hasCoupleWhatsApp, isTrue);
      expect(named.quotedAmountLyd, 1000);
      expect(named.withConsumerContact().hasCoupleWhatsApp, isFalse);
    });
  });

  group('ReportWrite', () {
    test('inserts a review report and rejects an empty reason', () {
      final row = ReportWrite.insert(
        reportedBy: 'u1',
        targetType: ReportWrite.reviewTarget,
        targetId: 'r1',
        reason: '  spam  ',
      );
      expect(row['target_type'], 'review');
      expect(row['target_id'], 'r1');
      expect(row['reason'], 'spam');
      expect(
        () => ReportWrite.insert(
          reportedBy: 'u1',
          targetType: ReportWrite.reviewTarget,
          targetId: 'r1',
          reason: '   ',
        ),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'report_reason_required',
          ),
        ),
      );
    });

    test('rejects a target that is not vendor or review', () {
      expect(
        () => ReportWrite.insert(
          reportedBy: 'u1',
          targetType: 'booking',
          targetId: 'b1',
          reason: 'nope',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });

  group('source: product gaps are wired', () {
    test('favorites reuse the Discover ratings roll-up', () {
      final fav = File('lib/features/favorites/providers/favorites_provider.dart')
          .readAsStringSync();
      expect(fav, contains('attachVendorRatings'));
      final rollup = File(
        'lib/features/discovery/providers/vendors_provider.dart',
      ).readAsStringSync();
      expect(rollup, contains('applyVendorRatingRows'));
      expect(rollup, contains('CommissionMath.parseLyd'));
      expect(rollup, isNot(contains("(row['rating'] as num)")));
    });

    test('vendor inbox loads booking_party_contact', () {
      final inbox = File(
        'lib/features/booking/providers/booking_provider.dart',
      ).readAsStringSync();
      expect(inbox, contains('attachBookingPartyContacts'));
      expect(inbox, contains(BookingSelect.partyContactTable));
      expect(inbox, contains('try {'));
      expect(inbox, contains('applyBookingPartyContactRows'));
      expect(
        File('lib/features/vendor_profile/screens/vendor_inbox_screen.dart')
            .readAsStringSync(),
        contains('hasCoupleWhatsApp'),
      );
    });

    test('profile edit is auth-gated and offered from Profile', () {
      expect(kAuthProtectedPrefixes, contains('/profile/edit'));
      expect(
        resolveAuthRedirect(
          location: '/profile/edit',
          status: AuthFlowStatus.unauthenticated,
          uri: Uri.parse('/profile/edit'),
        ),
        '/auth/login?from=${Uri.encodeComponent('/profile/edit')}',
      );
      expect(
        resolveAuthRedirect(
          location: '/profile/edit',
          status: AuthFlowStatus.authenticated,
          uri: Uri.parse('/profile/edit'),
        ),
        isNull,
      );
      expect(
        File('lib/features/auth/screens/profile_tab_screen.dart')
            .readAsStringSync(),
        contains("context.push('/profile/edit')"),
      );
      expect(
        File('lib/features/auth/screens/profile_tab_screen.dart')
            .readAsStringSync(),
        contains('updateLocale'),
      );
    });

    test('vendor detail can report a review', () {
      final detail = File(
        'lib/features/vendor_profile/screens/vendor_detail_screen.dart',
      ).readAsStringSync();
      expect(detail, contains('ReportWrite.reviewTarget'));
      expect(detail, contains('reportReview'));
      expect(detail, isNot(contains("target_type': 'vendor'")));
    });
  });
}
