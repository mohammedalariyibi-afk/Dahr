import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/models.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/booking/providers/booking_provider.dart';
import 'package:dahr/features/booking/screens/consumer_booking_detail_screen.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

final _booking = BookingRequest(
  id: 'b1',
  vendorId: 'v1',
  consumerId: 'c1',
  eventDate: DateTime(2030, 6, 15),
  status: BookingStatus.accepted,
  quotedAmountLyd: 2500,
  commissionAmountLyd: 250,
  commissionStatus: CommissionStatus.unpaid,
  vendor: const VendorProfile(
    id: 'v1',
    profileId: 'p1',
    businessName: 'Studio Noor',
    category: VendorCategory.photography,
    city: CityCode.tripoli,
  ),
);

Widget _host({
  required AsyncValue<PlatformBankDetails> bank,
  required AsyncValue<List<CommissionTransferNote>> notes,
}) {
  return ProviderScope(
    overrides: [
      bookingByIdProvider.overrideWith((ref, id) async => _booking),
      platformBankDetailsProvider.overrideWith((ref) => bank.when(
            data: (value) async => value,
            error: (e, _) => throw e,
            loading: () => Future<PlatformBankDetails>.delayed(
              const Duration(days: 1),
              () => PlatformBankDetails.unset,
            ),
          )),
      transferNotesByBookingProvider.overrideWith((ref, id) => notes.when(
            data: (value) async => value,
            error: (e, _) => throw e,
            loading: () => Future<List<CommissionTransferNote>>.delayed(
              const Duration(days: 1),
              () => const [],
            ),
          )),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const ConsumerBookingDetailScreen(bookingId: 'b1'),
    ),
  );
}

void main() {
  testWidgets('bank read failure shows SafeUserError, not ops pending',
      (tester) async {
    await tester.pumpWidget(
      _host(
        bank: AsyncError(Exception('postgrest boom'), StackTrace.current),
        notes: const AsyncData([]),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Something went wrong. Try again.'), findsWidgets);
    expect(find.text('Bank details coming from ops.'), findsNothing);
    expect(find.text('I transferred'), findsNothing);
    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('transfer-note read failure hides the empty-note form',
      (tester) async {
    await tester.pumpWidget(
      _host(
        bank: const AsyncData(
          PlatformBankDetails(
            bankName: 'Example Bank',
            accountHolder: 'Dahr Operator',
            accountNumber: 'PLACEHOLDER-ONLY',
          ),
        ),
        notes: AsyncError(Exception('notes failed'), StackTrace.current),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Something went wrong. Try again.'), findsWidgets);
    expect(find.text('I transferred'), findsNothing);
    expect(find.textContaining('Example Bank'), findsNothing);
  });
}
