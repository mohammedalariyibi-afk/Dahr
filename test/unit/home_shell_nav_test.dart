import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/discovery/screens/home_shell.dart';

void main() {
  group('homeShellIndexForLocation', () {
    test('couples highlight Bookings on /bookings', () {
      expect(
        homeShellIndexForLocation('/bookings', isVendor: false),
        2,
      );
    });

    test('vendors do not highlight Inbox on /bookings', () {
      expect(
        homeShellIndexForLocation('/bookings', isVendor: true),
        3,
      );
    });

    test('vendor Inbox still maps to the Inbox tab', () {
      expect(homeShellIndexForLocation('/inbox', isVendor: true), 2);
      expect(homeShellIndexForLocation('/inbox', isVendor: false), 2);
    });

    test('primary tabs stay stable for both roles', () {
      expect(homeShellIndexForLocation('/discover', isVendor: true), 0);
      expect(homeShellIndexForLocation('/favorites', isVendor: false), 1);
      expect(homeShellIndexForLocation('/profile', isVendor: true), 3);
    });
  });
}
