import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/models.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/vendor_profile/providers/vendor_provider.dart';
import 'package:dahr/features/vendor_profile/screens/vendor_edit_profile_screen.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

const _vendor = VendorProfile(
  id: 'v1',
  profileId: 'p1',
  businessName: 'Studio Noor',
  category: VendorCategory.photography,
  city: CityCode.tripoli,
  description: 'Portraits',
  whatsappNumber: '912345678',
  priceMin: 500,
  priceMax: 2000,
);

Widget _host({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      myVendorProfileProvider.overrideWith((ref) async => _vendor),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const VendorEditProfileScreen(),
    ),
  );
}

void main() {
  testWidgets('photos row chevron flips on the X axis in Arabic RTL',
      (tester) async {
    await tester.pumpWidget(_host(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('إدارة الصور'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byIcon(Icons.chevron_right))),
      TextDirection.rtl,
    );
    final flip = tester.widget<Transform>(
      find.byKey(const ValueKey('editListingPhotosChevron')),
    );
    expect(flip.transform.entry(0, 0), -1.0);
  });

  testWidgets('photos row chevron is not flipped in English LTR',
      (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byIcon(Icons.chevron_right))),
      TextDirection.ltr,
    );
    final flip = tester.widget<Transform>(
      find.byKey(const ValueKey('editListingPhotosChevron')),
    );
    expect(flip.transform.entry(0, 0), 1.0);
  });

  testWidgets('category dropdown does not offer Beauty', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(DropdownButtonFormField<VendorCategory>));
    await tester.pumpAndSettle();

    expect(find.text('Photography'), findsWidgets);
    expect(find.text('Venues'), findsOneWidget);
    expect(find.text('Other'), findsOneWidget);
    expect(find.text('Beauty'), findsNothing);
  });
}
