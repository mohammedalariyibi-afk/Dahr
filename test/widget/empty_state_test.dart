import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';
import 'package:dahr/shared/widgets/async_body.dart';

void main() {
  Widget host({required Widget child, Locale locale = const Locale('en')}) {
    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  testWidgets('shows title, message, and action', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      host(
        child: EmptyState(
          title: 'No vendors here',
          message: 'Approved vendors will appear here.',
          actionLabel: 'Clear',
          onAction: () => tapped = true,
        ),
      ),
    );

    expect(find.text('No vendors here'), findsOneWidget);
    expect(find.text('Approved vendors will appear here.'), findsOneWidget);
    await tester.tap(find.text('Clear'));
    expect(tapped, isTrue);
  });

  testWidgets('renders Arabic empty copy', (tester) async {
    await tester.pumpWidget(
      host(
        locale: const Locale('ar'),
        child: const EmptyState(
          title: 'لا توجد طلبات',
          message: 'عندما يطلب الأزواج تاريخاً سيظهر هنا.',
        ),
      ),
    );

    expect(find.text('لا توجد طلبات'), findsOneWidget);
    expect(
      find.text('عندما يطلب الأزواج تاريخاً سيظهر هنا.'),
      findsOneWidget,
    );
  });
}
