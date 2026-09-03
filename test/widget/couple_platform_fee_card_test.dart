import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/models.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';
import 'package:dahr/shared/widgets/couple_platform_fee_card.dart';

void main() {
  Widget host({
    required PlatformBankDetails bank,
    CommissionStatus status = CommissionStatus.unpaid,
    CommissionTransferNote? note,
    Locale locale = const Locale('en'),
    TextEditingController? controller,
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: SingleChildScrollView(
          child: CouplePlatformFeeCard(
            amountLyd: 250,
            status: status,
            bankDetails: bank,
            submittedNote: note,
            noteController: controller,
            onSubmitTransfer: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('unpaid couple fee shows LYD amount and bank-transfer copy',
      (tester) async {
    await tester.pumpWidget(host(bank: PlatformBankDetails.unset));
    expect(find.text('Dahr platform fee (10%)'), findsOneWidget);
    expect(find.text('250 LYD'), findsOneWidget);
    expect(
      find.textContaining('online bank transfer'),
      findsOneWidget,
    );
    expect(find.textContaining('WhatsApp'), findsOneWidget);
    expect(find.text('Bank details coming from ops.'), findsOneWidget);
    expect(find.text('I transferred'), findsOneWidget);
    expect(find.text('Pay now'), findsNothing);
    expect(find.textContaining('card number'), findsNothing);
    expect(find.textContaining('Stripe'), findsNothing);
  });

  testWidgets('shows configured bank details without inventing an account',
      (tester) async {
    await tester.pumpWidget(
      host(
        bank: const PlatformBankDetails(
          bankName: 'Example Bank',
          accountHolder: 'Dahr Operator',
          accountNumber: 'PLACEHOLDER-ONLY',
          bankNote: 'Use the booking date as reference',
        ),
      ),
    );
    expect(find.text('Bank details coming from ops.'), findsNothing);
    expect(find.textContaining('Example Bank'), findsOneWidget);
    expect(find.textContaining('Dahr Operator'), findsOneWidget);
    expect(find.textContaining('PLACEHOLDER-ONLY'), findsOneWidget);
    expect(find.textContaining('Use the booking date as reference'), findsOneWidget);
  });

  testWidgets('submitted note hides I transferred and does not mark paid',
      (tester) async {
    await tester.pumpWidget(
      host(
        bank: PlatformBankDetails.unset,
        note: const CommissionTransferNote(
          id: 'n1',
          bookingId: 'b1',
          consumerId: 'c1',
          referenceNote: 'Ref 9988',
        ),
      ),
    );
    expect(find.text('I transferred'), findsNothing);
    expect(find.textContaining('Ref 9988'), findsOneWidget);
    expect(find.text('Paid'), findsNothing);
  });

  testWidgets('renders Arabic unpaid fee and pending bank copy', (tester) async {
    await tester.pumpWidget(
      host(bank: PlatformBankDetails.unset, locale: const Locale('ar')),
    );
    expect(find.text('رسوم منصة دهر (10%)'), findsOneWidget);
    expect(find.text('250 LYD'), findsOneWidget);
    expect(find.text('بيانات البنك ستأتي من التشغيل.'), findsOneWidget);
    expect(find.text('حوّلت المبلغ'), findsOneWidget);
    expect(find.text('ادفع الآن'), findsNothing);
  });
}
