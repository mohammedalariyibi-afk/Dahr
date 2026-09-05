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

String localizeErrorKey(AppLocalizations l10n, String key) {
  switch (key) {
    case 'event_date_past':
      return l10n.eventDatePast;
    case 'guest_count_invalid':
      return l10n.invalidGuestCount;
    case 'date_unavailable':
      return l10n.dateUnavailable;
    case 'vendor_required':
    case 'consumer_required':
    case 'booking_required':
      return l10n.requiredField;
    case 'message_too_long':
    case 'comment_too_long':
      return l10n.errorGeneric;
    case 'rating_invalid':
      return l10n.ratingLabel;
    case 'quoted_amount_required':
      return l10n.quotedAmountRequired;
    case 'cannot_book_own_listing':
      return l10n.cannotBookOwnListing;
    case 'already_reviewed':
      return l10n.alreadyReviewed;
    case 'review_only_completed':
      return l10n.reviewOnlyCompleted;
    default:
      if (key.contains('date_unavailable')) return l10n.dateUnavailable;
      return l10n.errorGeneric;
  }
}

String formatDay(DateTime date) =>
    date.toIso8601String().split('T').first;
