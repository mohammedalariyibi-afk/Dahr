// Handwritten fallback mirroring flutter gen-l10n output.
// Prefer `flutter gen-l10n` in CI; this allows analyze/compile without codegen.
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

abstract class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    final l = Localizations.of<AppLocalizations>(context, AppLocalizations);
    assert(l != null, 'No AppLocalizations found in context');
    return l!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('ar'),
    Locale('en'),
  ];

  String get appName;
  String get splashTagline;
  String get chooseLanguage;
  String get languageArabic;
  String get languageEnglish;
  String get continueLabel;
  String get skipAsGuest;
  String get loginTitle;
  String get loginSubtitle;
  String get phoneLabel;
  String get phoneHint;
  String get phonePrefix;
  String get emailLabel;
  String get emailHint;
  String get continueWithEmail;
  String get continueWithPhone;
  String get sendOtp;
  String get otpTitle;
  String get otpSubtitle;
  String get otpLabel;
  String get verifyOtp;
  String get resendOtp;
  String get invalidPhone;
  String get invalidEmail;
  String get invalidOtp;
  String get roleTitle;
  String get roleConsumer;
  String get roleConsumerDesc;
  String get roleVendor;
  String get roleVendorDesc;
  String get profileSetupTitle;
  String get fullNameLabel;
  String get cityLabel;
  String get cityTripoli;
  String get cityBenghazi;
  String get weddingDateLabel;
  String get saveProfile;
  String get tabDiscover;
  String get tabFavorites;
  String get tabBookings;
  String get tabInbox;
  String get tabProfile;
  String get searchHint;
  String get filters;
  String get allCategories;
  String get priceMin;
  String get priceMax;
  String get applyFilters;
  String get clearFilters;
  String get categoryVenues;
  String get categoryPhotography;
  String get categoryCatering;
  String get categoryDresses;
  String get categoryBeauty;
  String get categoryMusic;
  String get categoryCars;
  String get categoryDecor;
  String get categoryOther;
  String get bookNow;
  String get whatsapp;
  String get favorite;
  String get unfavorite;
  String get report;
  String get reportReason;
  String get reportSubmit;
  String get reportSuccess;
  String get reviews;
  String get noReviews;
  String get description;
  String get services;
  String get priceRange;
  String get views;
  String get bookingTitle;
  String get eventDateLabel;
  String get guestCountLabel;
  String get messageLabel;
  String get messageHint;
  String get submitBooking;
  String get bookingSuccess;
  String get myBookings;
  String get noBookings;
  String get statusPending;
  String get statusAccepted;
  String get statusDeclined;
  String get statusCompleted;
  String get leaveReview;
  String get reviewTitle;
  String get ratingLabel;
  String get commentLabel;
  String get submitReview;
  String get reviewSuccess;
  String get favoritesTitle;
  String get noFavorites;
  String get loginRequired;
  String get loginRequiredBody;
  String get loginAction;
  String get vendorOnboardingTitle;
  String get businessNameLabel;
  String get categoryLabel;
  String get descriptionLabel;
  String get whatsappNumberLabel;
  String get priceMinLabel;
  String get priceMaxLabel;
  String get servicesLabel;
  String get submitOnboarding;
  String get onboardingPending;
  String get vendorDashboard;
  String get pendingRequests;
  String get acceptedRequests;
  String get vendorInbox;
  String get accept;
  String get decline;
  String get complete;
  String get noInboxItems;
  String get availabilityTitle;
  String get markBooked;
  String get markAvailable;
  String get editVendorProfile;
  String get saveChanges;
  String get signOut;
  String get guestBrowse;
  String get retry;
  String get errorGeneric;
  String get emptyDefault;
  String get loading;
  String get cancel;
  String get ok;
  String get verified;
  String get currencyLyd;
  String get profileTitle;
  String get language;
  String get vendorTools;
  String get manageAvailability;
  String get editListing;
  String get becomeVendor;
  String get seeAll;
  String get pickDate;
  String get requiredField;
  String get photosLabel;
  String get addPhoto;
  String get photoUploadFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(_lookup(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations _lookup(Locale locale) {
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ar':
    default:
      return AppLocalizationsAr();
  }
}
