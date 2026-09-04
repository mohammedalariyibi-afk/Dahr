import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/auth/widgets/profile_details_fields.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

void main() {
  Widget host({required Widget child, Locale locale = const Locale('en')}) {
    return MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );
  }

  testWidgets('couple form collects a Libya mobile for WhatsApp, not login',
      (tester) async {
    final name = TextEditingController();
    final phone = TextEditingController();
    await tester.pumpWidget(
      host(
        child: ProfileDetailsFields(
          nameController: name,
          phoneController: phone,
          city: CityCode.tripoli,
          onCityChanged: (_) {},
          showCoupleFields: true,
        ),
      ),
    );

    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Phone number'), findsOneWidget);
    expect(find.textContaining('+218'), findsWidgets);
    expect(
      find.textContaining('not used to sign in'),
      findsOneWidget,
    );
    expect(find.text('Wedding date (optional)'), findsOneWidget);
  });

  testWidgets('vendor form still shows phone but hides wedding date',
      (tester) async {
    await tester.pumpWidget(
      host(
        child: ProfileDetailsFields(
          nameController: TextEditingController(),
          phoneController: TextEditingController(),
          city: CityCode.benghazi,
          onCityChanged: (_) {},
          showCoupleFields: false,
        ),
      ),
    );

    expect(find.text('Phone number'), findsOneWidget);
    expect(find.text('Wedding date (optional)'), findsNothing);
  });
}
