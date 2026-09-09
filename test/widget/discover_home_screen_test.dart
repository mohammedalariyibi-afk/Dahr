import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/vendor.dart';
import 'package:dahr/core/theme/app_theme.dart';
import 'package:dahr/features/discovery/providers/vendors_provider.dart';
import 'package:dahr/features/discovery/screens/discover_home_screen.dart';
import 'package:dahr/features/favorites/providers/favorites_provider.dart';
import 'package:dahr/l10n/generated/app_localizations.dart';

class _EmptyVendors extends VendorsNotifier {
  @override
  Future<List<VendorProfile>> build() async => [];
}

class _EmptyFavorites extends FavoritesNotifier {
  @override
  Future<Set<String>> build() async => {};
}

Widget _host({Locale locale = const Locale('en')}) {
  return ProviderScope(
    overrides: [
      vendorsProvider.overrideWith(_EmptyVendors.new),
      favoritesProvider.overrideWith(_EmptyFavorites.new),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const DiscoverHomeScreen(),
    ),
  );
}

void main() {
  testWidgets('Discover chips omit Beauty', (tester) async {
    await tester.pumpWidget(_host());
    await tester.pumpAndSettle();

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Venues'), findsOneWidget);
    expect(find.text('Beauty'), findsNothing);
    expect(
      VendorCategory.values.map((e) => e.name),
      isNot(contains('beauty')),
    );
  });

  testWidgets('Arabic Discover chips omit تجميل', (tester) async {
    await tester.pumpWidget(_host(locale: const Locale('ar')));
    await tester.pumpAndSettle();

    expect(find.text('الكل'), findsOneWidget);
    expect(find.text('قاعات'), findsOneWidget);
    expect(find.text('تجميل'), findsNothing);
  });
}
