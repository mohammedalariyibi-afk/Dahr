import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/vendor.dart';

void main() {
  test('beauty is not a selectable VendorCategory', () {
    expect(VendorCategory.values.map((e) => e.name), isNot(contains('beauty')));
    expect(VendorCategory.values, contains(VendorCategory.other));
    expect(VendorCategory.values, contains(VendorCategory.venues));
  });

  test('legacy beauty rows remap to other', () {
    expect(VendorCategory.fromString('beauty'), VendorCategory.other);
    expect(VendorCategory.fromString(VendorCategory.retiredBeautyDb),
        VendorCategory.other);
    expect(VendorCategory.fromString('venues'), VendorCategory.venues);
    expect(VendorCategory.fromString('unknown'), VendorCategory.other);
    expect(
      VendorProfile.fromJson({
        'id': 'c1',
        'profile_id': 'b1',
        'business_name': 'ميكب نور',
        'category': 'beauty',
        'city': 'benghazi',
      }).category,
      VendorCategory.other,
    );
  });

  test('Discover and Favorites exclude leftover beauty listings', () {
    final discover = File(
      'lib/features/discovery/providers/vendors_provider.dart',
    ).readAsStringSync();
    final favorites = File(
      'lib/features/favorites/providers/favorites_provider.dart',
    ).readAsStringSync();
    expect(
      discover,
      contains(".neq('category', VendorCategory.retiredBeautyDb)"),
    );
    expect(
      favorites,
      contains(".neq('category', VendorCategory.retiredBeautyDb)"),
    );
  });

  test('chips, dropdowns, and copy no longer offer Beauty', () {
    expect(
      File('lib/features/discovery/screens/discover_home_screen.dart')
          .readAsStringSync(),
      contains('VendorCategory.values'),
    );
    expect(
      File('lib/features/vendor_profile/screens/vendor_onboarding_screen.dart')
          .readAsStringSync(),
      contains('VendorCategory.values'),
    );
    expect(
      File('lib/l10n/app_en.arb').readAsStringSync(),
      isNot(contains('categoryBeauty')),
    );
    expect(
      File('lib/l10n/app_ar.arb').readAsStringSync(),
      isNot(contains('categoryBeauty')),
    );
    expect(
      File('lib/l10n/generated/app_localizations.dart').readAsStringSync(),
      isNot(contains('categoryBeauty')),
    );
    final store = File('docs/store-listing.md').readAsStringSync();
    expect(store.toLowerCase(), isNot(contains('beauty')));
    expect(store, isNot(contains('تجميل')));
  });

  test('seed and migration recategorize beauty instead of dropping the enum', () {
    final seed = File('supabase/seed.sql').readAsStringSync();
    expect(seed, isNot(contains("'beauty'")));
    final sql = File(
      'supabase/migrations/20260909120000_retire_beauty_category.sql',
    ).readAsStringSync();
    expect(sql, contains("SET category = 'other'"));
    expect(sql, contains("WHERE category = 'beauty'"));
    expect(sql.toLowerCase(), isNot(contains('drop type')));
    expect(sql.toLowerCase(), isNot(contains('drop value')));
  });

  test('admin labels omit beauty and leftover rows display as Other', () {
    final admin = File('admin/src/lib/admin.ts').readAsStringSync();
    expect(admin, contains('venues: "Venues"'));
    expect(admin, isNot(contains('beauty: "Beauty"')));
    expect(admin, contains('if (category === "beauty")'));
    expect(
      File('admin/src/app/(admin)/vendors/page.tsx').readAsStringSync(),
      contains('categoryLabel(vendor.category)'),
    );
  });
}
