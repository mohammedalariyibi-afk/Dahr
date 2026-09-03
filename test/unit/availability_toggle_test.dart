import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/review.dart';
import 'package:dahr/core/models/enums.dart';

void main() {
  AvailabilitySlot slot(String date, String status) => AvailabilitySlot(
        id: date,
        vendorId: 'v1',
        date: DateTime.parse(date),
        status: status,
      );

  group('AvailabilityCalendar.toggle', () {
    test('flips booked to available and available to booked', () {
      expect(
        AvailabilityCalendar.toggle(AvailabilityStatus.booked),
        AvailabilityStatus.available,
      );
      expect(
        AvailabilityCalendar.toggle(AvailabilityStatus.available),
        AvailabilityStatus.booked,
      );
    });

    test('tapping an unmarked date marks it booked', () {
      final next = AvailabilityCalendar.nextStatusForDate(
        date: DateTime(2030, 6, 15),
        slots: const [],
      );
      expect(next, AvailabilityStatus.booked);
    });

    test('tapping a booked date marks it available', () {
      final next = AvailabilityCalendar.nextStatusForDate(
        date: DateTime(2030, 6, 15),
        slots: [slot('2030-06-15', 'booked')],
      );
      expect(next, AvailabilityStatus.available);
    });

    test('tapping an available date marks it booked', () {
      final next = AvailabilityCalendar.nextStatusForDate(
        date: DateTime(2030, 6, 15),
        slots: [slot('2030-06-15', 'available')],
      );
      expect(next, AvailabilityStatus.booked);
    });
  });

  group('AvailabilityCalendar booked dates', () {
    test('collects booked keys and upcoming dates', () {
      final slots = [
        slot('2030-06-15', 'booked'),
        slot('2030-06-16', 'available'),
        slot('2020-01-01', 'booked'),
      ];
      expect(
        AvailabilityCalendar.bookedDateKeys(slots),
        {'2030-06-15', '2020-01-01'},
      );
      expect(
        AvailabilityCalendar.isBookedDate(
          DateTime(2030, 6, 15),
          {'2030-06-15'},
        ),
        isTrue,
      );
      final upcoming = AvailabilityCalendar.upcomingBookedDates(
        slots,
        from: DateTime(2030, 1, 1),
      );
      expect(upcoming.map(AvailabilityCalendar.dateKey), ['2030-06-15']);
    });

    test('upsert json uses yyyy-MM-dd and status name', () {
      expect(
        AvailabilityCalendar.upsertJson(
          vendorId: 'v1',
          date: DateTime(2030, 6, 5),
          status: AvailabilityStatus.booked,
        ),
        {
          'vendor_id': 'v1',
          'date': '2030-06-05',
          'status': 'booked',
        },
      );
    });
  });
}
