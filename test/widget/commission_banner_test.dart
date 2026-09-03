import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';
import 'package:dahr/shared/widgets/commission_banner.dart';

void main() {
  Widget host({
    required double unpaid,
    Locale locale = const Locale('en'),
  }) {
    return MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(
        body: VendorCommissionBanner(unpaidTotalLyd: unpaid),
      ),
    );
  }

  testWidgets('hides when nothing is owed', (tester) async {
    await tester.pumpWidget(host(unpaid: 0));
    expect(find.text('Commission owed to Dahr'), findsNothing);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('shows LYD total without pay instructions', (tester) async {
    await tester.pumpWidget(host(unpaid: 250));
    expect(find.text('Commission owed to Dahr'), findsOneWidget);
    expect(find.text('Unpaid total: 250 LYD'), findsOneWidget);
    expect(find.textContaining('WhatsApp'), findsNothing);
    expect(find.textContaining('bank'), findsNothing);
    expect(find.textContaining('IBAN'), findsNothing);
  });

  testWidgets('renders Arabic unpaid total', (tester) async {
    await tester.pumpWidget(host(unpaid: 100.5, locale: const Locale('ar')));
    expect(find.text('العمولة المستحقة لدهر'), findsOneWidget);
    expect(find.textContaining('100.50 LYD'), findsOneWidget);
  });
}
