import '../models/enums.dart';
import '../../l10n/generated/app_localizations.dart';

String localizedCategory(AppLocalizations l10n, VendorCategory category) {
  switch (category) {
    case VendorCategory.venues:
      return l10n.categoryVenues;
    case VendorCategory.photography:
      return l10n.categoryPhotography;
    case VendorCategory.catering:
      return l10n.categoryCatering;
    case VendorCategory.dresses:
      return l10n.categoryDresses;
    case VendorCategory.beauty:
      return l10n.categoryBeauty;
    case VendorCategory.music:
      return l10n.categoryMusic;
    case VendorCategory.cars:
      return l10n.categoryCars;
    case VendorCategory.decor:
      return l10n.categoryDecor;
    case VendorCategory.other:
      return l10n.categoryOther;
  }
}
