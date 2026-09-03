import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

String _classBody(String src, String className, [String? untilClass]) {
  final start = src.indexOf('class $className');
  expect(start, greaterThanOrEqualTo(0), reason: 'missing class $className');
  final end = untilClass == null
      ? src.length
      : src.indexOf('class $untilClass', start + 1);
  expect(end, greaterThan(start), reason: 'missing end for $className');
  return src.substring(start, end);
}

void main() {
  late String bookingProvider;
  late String leaveReview;
  late String consumerBookingsScreen;
  late String bookingRequestScreen;
  late String vendorInbox;
  late String adminActions;
  late String adminBookingWrite;
  late String adminReviewWrite;

  setUpAll(() {
    bookingProvider =
        File('lib/features/booking/providers/booking_provider.dart')
            .readAsStringSync();
    leaveReview =
        File('lib/features/reviews/screens/leave_review_screen.dart')
            .readAsStringSync();
    consumerBookingsScreen =
        File('lib/features/booking/screens/consumer_bookings_screen.dart')
            .readAsStringSync();
    bookingRequestScreen =
        File('lib/features/booking/screens/booking_request_screen.dart')
            .readAsStringSync();
    vendorInbox =
        File('lib/features/vendor_profile/screens/vendor_inbox_screen.dart')
            .readAsStringSync();
    adminActions =
        File('admin/src/app/(admin)/actions.ts').readAsStringSync();
    adminBookingWrite =
        File('admin/src/lib/booking-write.ts').readAsStringSync();
    adminReviewWrite = File('admin/src/lib/review-write.ts').readAsStringSync();
  });

  group('consumers never call booking update', () {
    test('ConsumerBookingsNotifier inserts and never .update()', () {
      final consumer = _classBody(
        bookingProvider,
        'ConsumerBookingsNotifier',
        'VendorInboxNotifier',
      );
      expect(consumer.contains('.insert('), isTrue);
      expect(consumer.contains('.update('), isFalse);
      expect(consumer.contains('BookingStatusWrite.consumerInsert'), isTrue);
      expect(consumer.contains('consumerUpdate'), isFalse);
    });

    test('couple booking screens never .update() booking_requests', () {
      expect(consumerBookingsScreen.contains('.update('), isFalse);
      expect(bookingRequestScreen.contains('.update('), isFalse);
      expect(consumerBookingsScreen.contains('.from(\'booking_requests\')'), isFalse);
    });

    test('vendor inbox still updates via vendor guard and accept RPC', () {
      final vendor = _classBody(
        bookingProvider,
        'VendorInboxNotifier',
      );
      expect(vendor.contains('.update('), isTrue);
      expect(vendor.contains('BookingStatusWrite.vendorDirectPatch'), isTrue);
      expect(vendor.contains('BookingStatusWrite.acceptRpcName'), isTrue);
      expect(vendorInbox.contains('acceptBooking'), isTrue);
      expect(vendorInbox.contains('updateStatus'), isTrue);
    });
  });

  group('consumers never call review update or is_hidden', () {
    test('leave-review flow is insert-only without is_hidden', () {
      expect(leaveReview.contains('.insert('), isTrue);
      expect(leaveReview.contains('.update('), isFalse);
      expect(leaveReview.contains('is_hidden'), isFalse);
      expect(leaveReview.contains('ReviewWrite.consumerInsert'), isTrue);
      expect(leaveReview.contains('consumerUpdate'), isFalse);
      expect(leaveReview.contains('adminHidePatch'), isFalse);
    });

    test('Flutter feature code never updates reviews', () {
      final reviewFiles = Directory('lib/features')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'));
      for (final file in reviewFiles) {
        final src = file.readAsStringSync();
        if (!src.contains("from('reviews')")) continue;
        expect(
          src.contains('.update('),
          isFalse,
          reason: '${file.path} must not UPDATE reviews',
        );
      }
    });
  });

  group('admin write guards match live Dahr LY', () {
    test('hideReview uses the admin-only is_hidden patch', () {
      expect(adminActions.contains('adminHideReviewPatch()'), isTrue);
      expect(adminActions.contains('from("reviews")'), isTrue);
      expect(adminReviewWrite.contains('is_hidden: true'), isTrue);
      expect(adminReviewWrite.contains('consumerReviewUpdate'), isTrue);
      expect(adminReviewWrite.contains('write_rejected'), isTrue);
    });

    test('admin booking guard forbids couple updates, allows vendor/admin', () {
      expect(adminBookingWrite.contains('CONSUMER_MAY_UPDATE = false'), isTrue);
      expect(adminBookingWrite.contains('CONSUMER_MAY_CANCEL = false'), isTrue);
      expect(adminBookingWrite.contains('consumerBookingUpdate'), isTrue);
      expect(adminBookingWrite.contains('accept_booking_request'), isTrue);
      expect(adminBookingWrite.contains('canUpdateBooking(actor)'), isTrue);
    });

    test('admin actions do not add a couple booking or review update path', () {
      expect(adminActions.contains('from("booking_requests")'), isFalse);
      expect(adminActions.contains('consumerReviewUpdate'), isFalse);
      expect(adminActions.contains('consumerBookingUpdate'), isFalse);
    });
  });
}
