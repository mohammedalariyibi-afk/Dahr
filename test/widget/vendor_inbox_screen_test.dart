import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/models.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/booking/providers/booking_provider.dart';
import 'package:dahr/features/vendor_profile/screens/vendor_inbox_screen.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

class _StubInbox extends VendorInboxNotifier {
  _StubInbox(this._bookings);

  final List<BookingRequest> _bookings;

  @override
  Future<List<BookingRequest>> build() async => _bookings;
}

BookingRequest _booking({
  required BookingStatus status,
  CommissionStatus? commissionStatus,
}) {
  return BookingRequest(
    id: 'b1',
    vendorId: 'v1',
    consumerId: 'c1',
    eventDate: DateTime(2030, 6, 15),
    status: status,
    quotedAmountLyd: 2500,
    commissionAmountLyd: 250,
    commissionStatus: commissionStatus,
    consumerName: 'Salma',
  );
}

Widget _host({
  required List<BookingRequest> bookings,
  BookingStatus? filter = BookingStatus.accepted,
  Locale locale = const Locale('en'),
}) {
  return ProviderScope(
    overrides: [
      vendorInboxProvider.overrideWith(() => _StubInbox(bookings)),
      vendorInboxFilterProvider.overrideWith((ref) => filter),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const VendorInboxScreen(),
    ),
  );
}

void main() {
  testWidgets('unpaid inbox commission includes couple-pays framing',
      (tester) async {
    await tester.pumpWidget(
      _host(
        bookings: [
          _booking(
            status: BookingStatus.accepted,
            commissionStatus: CommissionStatus.unpaid,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couple's Dahr fee (10%): 250 LYD"), findsOneWidget);
    expect(find.textContaining('Commission status: Unpaid'), findsOneWidget);
    expect(
      find.textContaining('You pay Dahr nothing'),
      findsOneWidget,
    );
  });

  testWidgets('paid inbox commission does not add the couple-pays hint',
      (tester) async {
    await tester.pumpWidget(
      _host(
        bookings: [
          _booking(
            status: BookingStatus.accepted,
            commissionStatus: CommissionStatus.paid,
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Couple's Dahr fee (10%): 250 LYD"), findsOneWidget);
    expect(
      find.textContaining('You pay Dahr nothing'),
      findsNothing,
    );
  });

  testWidgets('Arabic inbox unpaid commission uses the vendor note',
      (tester) async {
    await tester.pumpWidget(
      _host(
        bookings: [
          _booking(
            status: BookingStatus.accepted,
            commissionStatus: CommissionStatus.unpaid,
          ),
        ],
        locale: const Locale('ar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.textContaining('أنت لا تدفع لدهر شيئاً'),
      findsOneWidget,
    );
  });
}
