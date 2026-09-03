import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/vendor_profile/widgets/accept_booking_dialog.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

void main() {
  Widget host({required ValueChanged<double?> onResult}) {
    return MaterialApp(
      theme: AppTheme.dark,
      locale: const Locale('en'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final quoted = await showDialog<double>(
                  context: context,
                  builder: (context) => AcceptBookingDialog(
                    eventDate: DateTime(2030, 6, 15),
                  ),
                );
                onResult(quoted);
              },
              child: const Text('open-accept'),
            );
          },
        ),
      ),
    );
  }

  testWidgets('previews 10% unpaid commission in LYD then confirms',
      (tester) async {
    double? quoted;
    await tester.pumpWidget(host(onResult: (v) => quoted = v));
    await tester.tap(find.text('open-accept'));
    await tester.pumpAndSettle();

    expect(find.text('Accept booking'), findsOneWidget);
    expect(find.text('Event date: 2030-06-15'), findsOneWidget);
    expect(find.text('Quoted amount (LYD)'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '2500');
    await tester.pump();

    expect(find.text('Quote: 2500 LYD'), findsOneWidget);
    expect(find.text('Dahr commission (10%): 250 LYD'), findsOneWidget);
    expect(find.textContaining('You pay 10%'), findsNothing);
    expect(
      find.textContaining('The couple pays that fee to Dahr by bank transfer'),
      findsOneWidget,
    );
    expect(find.textContaining('Pay now'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, 'Confirm accept'));
    await tester.pumpAndSettle();
    expect(quoted, 2500);
  });

  testWidgets('confirm stays disabled until a valid quote is entered',
      (tester) async {
    await tester.pumpWidget(host(onResult: (_) {}));
    await tester.tap(find.text('open-accept'));
    await tester.pumpAndSettle();

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Confirm accept'),
    );
    expect(confirm.onPressed, isNull);

    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Confirm accept'),
          )
          .onPressed,
      isNull,
    );
  });
}
