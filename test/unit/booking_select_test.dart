import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/booking_select.dart';

void main() {
  group('BookingSelect', () {
    test('couple reads fee columns; insert stays money-free', () {
      expect(BookingSelect.includesCommission(BookingSelect.consumerList), isTrue);
      expect(BookingSelect.includesCommission(BookingSelect.consumerById), isTrue);
      expect(BookingSelect.includesCommission(BookingSelect.consumerInsert), isFalse);
      expect(BookingSelect.consumerList.contains('commission_amount_lyd'), isTrue);
      expect(BookingSelect.consumerById.contains('commission_status'), isTrue);
      expect(BookingSelect.consumerInsert.contains('quoted_amount_lyd'), isTrue);
      expect(BookingSelect.consumerInsert.contains('commission_'), isFalse);
    });

    test('vendor select includes unpaid commission columns', () {
      expect(BookingSelect.includesCommission(BookingSelect.vendor), isTrue);
      expect(BookingSelect.vendor.contains('commission_amount_lyd'), isTrue);
      expect(BookingSelect.vendor.contains('commission_status'), isTrue);
    });

    test('couple booking provider uses consumer selects', () {
      final src =
          File('lib/features/booking/providers/booking_provider.dart').readAsStringSync();
      expect(src, contains('BookingSelect.consumerList'));
      expect(src, contains('BookingSelect.consumerInsert'));
      expect(src, contains('BookingSelect.consumerById'));
      expect(src, contains('BookingSelect.vendor'));
      expect(src, isNot(contains(".select('*')")));
      expect(src, isNot(contains(".select()")));
    });
  });
}
