import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In ar, this message translates to:
  /// **'دهر'**
  String get appName;

  /// No description provided for @splashTagline.
  ///
  /// In ar, this message translates to:
  /// **'سوق الزفاف في ليبيا'**
  String get splashTagline;

  /// No description provided for @chooseLanguage.
  ///
  /// In ar, this message translates to:
  /// **'اختر اللغة'**
  String get chooseLanguage;

  /// No description provided for @languageArabic.
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageEnglish.
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @continueLabel.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get continueLabel;

  /// No description provided for @skipAsGuest.
  ///
  /// In ar, this message translates to:
  /// **'تصفح كزائر'**
  String get skipAsGuest;

  /// No description provided for @loginTitle.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل بريدك الإلكتروني لاستلام رمز الدخول لمرة واحدة'**
  String get loginSubtitle;

  /// No description provided for @phoneLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الهاتف'**
  String get phoneLabel;

  /// No description provided for @phoneHint.
  ///
  /// In ar, this message translates to:
  /// **'9XXXXXXXX'**
  String get phoneHint;

  /// No description provided for @phonePrefix.
  ///
  /// In ar, this message translates to:
  /// **'+218'**
  String get phonePrefix;

  /// No description provided for @emailLabel.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In ar, this message translates to:
  /// **'name@example.com'**
  String get emailHint;

  /// No description provided for @continueWithEmail.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة بالبريد الإلكتروني'**
  String get continueWithEmail;

  /// No description provided for @continueWithPhone.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة برقم الهاتف'**
  String get continueWithPhone;

  /// No description provided for @sendOtp.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الرمز'**
  String get sendOtp;

  /// No description provided for @otpTitle.
  ///
  /// In ar, this message translates to:
  /// **'تحقق من الرمز'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In ar, this message translates to:
  /// **'أدخل الرمز الذي أرسلناه إلى بريدك الإلكتروني'**
  String get otpSubtitle;

  /// No description provided for @otpLabel.
  ///
  /// In ar, this message translates to:
  /// **'رمز التحقق'**
  String get otpLabel;

  /// No description provided for @verifyOtp.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد'**
  String get verifyOtp;

  /// No description provided for @resendOtp.
  ///
  /// In ar, this message translates to:
  /// **'إعادة إرسال الرمز'**
  String get resendOtp;

  /// No description provided for @invalidPhone.
  ///
  /// In ar, this message translates to:
  /// **'رقم هاتف ليبي غير صالح'**
  String get invalidPhone;

  /// No description provided for @invalidEmail.
  ///
  /// In ar, this message translates to:
  /// **'بريد إلكتروني غير صالح'**
  String get invalidEmail;

  /// No description provided for @invalidOtp.
  ///
  /// In ar, this message translates to:
  /// **'رمز غير صالح'**
  String get invalidOtp;

  /// No description provided for @roleTitle.
  ///
  /// In ar, this message translates to:
  /// **'كيف ستستخدم دهر؟'**
  String get roleTitle;

  /// No description provided for @roleConsumer.
  ///
  /// In ar, this message translates to:
  /// **'أبحث عن مورّدين'**
  String get roleConsumer;

  /// No description provided for @roleConsumerDesc.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف واحجز خدمات الزفاف'**
  String get roleConsumerDesc;

  /// No description provided for @roleVendor.
  ///
  /// In ar, this message translates to:
  /// **'أنا مورّد'**
  String get roleVendor;

  /// No description provided for @roleVendorDesc.
  ///
  /// In ar, this message translates to:
  /// **'اعرض خدماتك واستقبل الطلبات'**
  String get roleVendorDesc;

  /// No description provided for @profileSetupTitle.
  ///
  /// In ar, this message translates to:
  /// **'أكمل ملفك'**
  String get profileSetupTitle;

  /// No description provided for @fullNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الكامل'**
  String get fullNameLabel;

  /// No description provided for @cityLabel.
  ///
  /// In ar, this message translates to:
  /// **'المدينة'**
  String get cityLabel;

  /// No description provided for @cityTripoli.
  ///
  /// In ar, this message translates to:
  /// **'طرابلس'**
  String get cityTripoli;

  /// No description provided for @cityBenghazi.
  ///
  /// In ar, this message translates to:
  /// **'بنغازي'**
  String get cityBenghazi;

  /// No description provided for @weddingDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الزفاف (اختياري)'**
  String get weddingDateLabel;

  /// No description provided for @saveProfile.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get saveProfile;

  /// No description provided for @tabDiscover.
  ///
  /// In ar, this message translates to:
  /// **'اكتشف'**
  String get tabDiscover;

  /// No description provided for @tabFavorites.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get tabFavorites;

  /// No description provided for @tabBookings.
  ///
  /// In ar, this message translates to:
  /// **'حجوزاتي'**
  String get tabBookings;

  /// No description provided for @tabInbox.
  ///
  /// In ar, this message translates to:
  /// **'الوارد'**
  String get tabInbox;

  /// No description provided for @tabProfile.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get tabProfile;

  /// No description provided for @searchHint.
  ///
  /// In ar, this message translates to:
  /// **'ابحث عن مورّدين…'**
  String get searchHint;

  /// No description provided for @filters.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get filters;

  /// No description provided for @allCategories.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get allCategories;

  /// No description provided for @priceMin.
  ///
  /// In ar, this message translates to:
  /// **'أقل سعر'**
  String get priceMin;

  /// No description provided for @priceMax.
  ///
  /// In ar, this message translates to:
  /// **'أعلى سعر'**
  String get priceMax;

  /// No description provided for @applyFilters.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get applyFilters;

  /// No description provided for @clearFilters.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get clearFilters;

  /// No description provided for @categoryVenues.
  ///
  /// In ar, this message translates to:
  /// **'قاعات'**
  String get categoryVenues;

  /// No description provided for @categoryPhotography.
  ///
  /// In ar, this message translates to:
  /// **'تصوير'**
  String get categoryPhotography;

  /// No description provided for @categoryCatering.
  ///
  /// In ar, this message translates to:
  /// **'ضيافة'**
  String get categoryCatering;

  /// No description provided for @categoryDresses.
  ///
  /// In ar, this message translates to:
  /// **'فساتين'**
  String get categoryDresses;

  /// No description provided for @categoryBeauty.
  ///
  /// In ar, this message translates to:
  /// **'تجميل'**
  String get categoryBeauty;

  /// No description provided for @categoryMusic.
  ///
  /// In ar, this message translates to:
  /// **'موسيقى'**
  String get categoryMusic;

  /// No description provided for @categoryCars.
  ///
  /// In ar, this message translates to:
  /// **'سيارات'**
  String get categoryCars;

  /// No description provided for @categoryDecor.
  ///
  /// In ar, this message translates to:
  /// **'ديكور'**
  String get categoryDecor;

  /// No description provided for @categoryOther.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get categoryOther;

  /// No description provided for @bookNow.
  ///
  /// In ar, this message translates to:
  /// **'اطلب حجزاً'**
  String get bookNow;

  /// No description provided for @whatsapp.
  ///
  /// In ar, this message translates to:
  /// **'واتساب'**
  String get whatsapp;

  /// No description provided for @favorite.
  ///
  /// In ar, this message translates to:
  /// **'إضافة للمفضلة'**
  String get favorite;

  /// No description provided for @unfavorite.
  ///
  /// In ar, this message translates to:
  /// **'إزالة من المفضلة'**
  String get unfavorite;

  /// No description provided for @report.
  ///
  /// In ar, this message translates to:
  /// **'إبلاغ'**
  String get report;

  /// No description provided for @reportReason.
  ///
  /// In ar, this message translates to:
  /// **'سبب البلاغ'**
  String get reportReason;

  /// No description provided for @reportSubmit.
  ///
  /// In ar, this message translates to:
  /// **'إرسال البلاغ'**
  String get reportSubmit;

  /// No description provided for @reportSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال البلاغ'**
  String get reportSuccess;

  /// No description provided for @reviews.
  ///
  /// In ar, this message translates to:
  /// **'التقييمات'**
  String get reviews;

  /// No description provided for @noReviews.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تقييمات بعد'**
  String get noReviews;

  /// No description provided for @description.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get description;

  /// No description provided for @services.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات'**
  String get services;

  /// No description provided for @priceRange.
  ///
  /// In ar, this message translates to:
  /// **'نطاق السعر'**
  String get priceRange;

  /// No description provided for @views.
  ///
  /// In ar, this message translates to:
  /// **'المشاهدات'**
  String get views;

  /// No description provided for @bookingTitle.
  ///
  /// In ar, this message translates to:
  /// **'طلب حجز'**
  String get bookingTitle;

  /// No description provided for @eventDateLabel.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ المناسبة'**
  String get eventDateLabel;

  /// No description provided for @guestCountLabel.
  ///
  /// In ar, this message translates to:
  /// **'عدد الضيوف'**
  String get guestCountLabel;

  /// No description provided for @messageLabel.
  ///
  /// In ar, this message translates to:
  /// **'رسالة'**
  String get messageLabel;

  /// No description provided for @messageHint.
  ///
  /// In ar, this message translates to:
  /// **'أخبر المورّد بتفاصيل إضافية…'**
  String get messageHint;

  /// No description provided for @submitBooking.
  ///
  /// In ar, this message translates to:
  /// **'إرسال الطلب'**
  String get submitBooking;

  /// No description provided for @bookingSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم إرسال طلب الحجز'**
  String get bookingSuccess;

  /// No description provided for @myBookings.
  ///
  /// In ar, this message translates to:
  /// **'حجوزاتي'**
  String get myBookings;

  /// No description provided for @noBookings.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حجوزات'**
  String get noBookings;

  /// No description provided for @statusPending.
  ///
  /// In ar, this message translates to:
  /// **'قيد الانتظار'**
  String get statusPending;

  /// No description provided for @statusAccepted.
  ///
  /// In ar, this message translates to:
  /// **'مقبول'**
  String get statusAccepted;

  /// No description provided for @statusDeclined.
  ///
  /// In ar, this message translates to:
  /// **'مرفوض'**
  String get statusDeclined;

  /// No description provided for @statusCompleted.
  ///
  /// In ar, this message translates to:
  /// **'مكتمل'**
  String get statusCompleted;

  /// No description provided for @leaveReview.
  ///
  /// In ar, this message translates to:
  /// **'اترك تقييماً'**
  String get leaveReview;

  /// No description provided for @reviewTitle.
  ///
  /// In ar, this message translates to:
  /// **'تقييم المورّد'**
  String get reviewTitle;

  /// No description provided for @ratingLabel.
  ///
  /// In ar, this message translates to:
  /// **'التقييم'**
  String get ratingLabel;

  /// No description provided for @commentLabel.
  ///
  /// In ar, this message translates to:
  /// **'تعليق'**
  String get commentLabel;

  /// No description provided for @submitReview.
  ///
  /// In ar, this message translates to:
  /// **'نشر التقييم'**
  String get submitReview;

  /// No description provided for @reviewSuccess.
  ///
  /// In ar, this message translates to:
  /// **'شكراً لتقييمك'**
  String get reviewSuccess;

  /// No description provided for @favoritesTitle.
  ///
  /// In ar, this message translates to:
  /// **'المفضلة'**
  String get favoritesTitle;

  /// No description provided for @noFavorites.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مفضلات بعد'**
  String get noFavorites;

  /// No description provided for @loginRequired.
  ///
  /// In ar, this message translates to:
  /// **'يلزم تسجيل الدخول'**
  String get loginRequired;

  /// No description provided for @loginRequiredBody.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الدخول للمتابعة'**
  String get loginRequiredBody;

  /// No description provided for @loginAction.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول'**
  String get loginAction;

  /// No description provided for @vendorOnboardingTitle.
  ///
  /// In ar, this message translates to:
  /// **'إعداد نشاطك'**
  String get vendorOnboardingTitle;

  /// No description provided for @businessNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'اسم النشاط'**
  String get businessNameLabel;

  /// No description provided for @categoryLabel.
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get categoryLabel;

  /// No description provided for @descriptionLabel.
  ///
  /// In ar, this message translates to:
  /// **'الوصف'**
  String get descriptionLabel;

  /// No description provided for @whatsappNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم واتساب'**
  String get whatsappNumberLabel;

  /// No description provided for @priceMinLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر من (د.ل)'**
  String get priceMinLabel;

  /// No description provided for @priceMaxLabel.
  ///
  /// In ar, this message translates to:
  /// **'السعر إلى (د.ل)'**
  String get priceMaxLabel;

  /// No description provided for @servicesLabel.
  ///
  /// In ar, this message translates to:
  /// **'الخدمات (مفصولة بفاصلة)'**
  String get servicesLabel;

  /// No description provided for @submitOnboarding.
  ///
  /// In ar, this message translates to:
  /// **'إرسال للمراجعة'**
  String get submitOnboarding;

  /// No description provided for @onboardingPending.
  ///
  /// In ar, this message translates to:
  /// **'بانتظار موافقة الإدارة'**
  String get onboardingPending;

  /// No description provided for @vendorDashboard.
  ///
  /// In ar, this message translates to:
  /// **'لوحة المورّد'**
  String get vendorDashboard;

  /// No description provided for @pendingRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات معلّقة'**
  String get pendingRequests;

  /// No description provided for @acceptedRequests.
  ///
  /// In ar, this message translates to:
  /// **'طلبات مقبولة'**
  String get acceptedRequests;

  /// No description provided for @vendorInbox.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الحجز'**
  String get vendorInbox;

  /// No description provided for @accept.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get accept;

  /// No description provided for @decline.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get decline;

  /// No description provided for @complete.
  ///
  /// In ar, this message translates to:
  /// **'إكمال'**
  String get complete;

  /// No description provided for @noInboxItems.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get noInboxItems;

  /// No description provided for @availabilityTitle.
  ///
  /// In ar, this message translates to:
  /// **'التوفر'**
  String get availabilityTitle;

  /// No description provided for @markBooked.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كمحجوز'**
  String get markBooked;

  /// No description provided for @markAvailable.
  ///
  /// In ar, this message translates to:
  /// **'تعيين كمتاح'**
  String get markAvailable;

  /// No description provided for @editVendorProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف'**
  String get editVendorProfile;

  /// No description provided for @saveChanges.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التغييرات'**
  String get saveChanges;

  /// No description provided for @signOut.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get signOut;

  /// No description provided for @guestBrowse.
  ///
  /// In ar, this message translates to:
  /// **'تصفح بدون حساب'**
  String get guestBrowse;

  /// No description provided for @retry.
  ///
  /// In ar, this message translates to:
  /// **'إعادة المحاولة'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In ar, this message translates to:
  /// **'حدث خطأ. حاول مرة أخرى.'**
  String get errorGeneric;

  /// No description provided for @vendorNotApprovedError.
  ///
  /// In ar, this message translates to:
  /// **'هذا المورّد لا يستقبل الطلبات بعد.'**
  String get vendorNotApprovedError;

  /// No description provided for @bookingAlreadyHandledError.
  ///
  /// In ar, this message translates to:
  /// **'تم التعامل مع هذا الطلب بالفعل. حدّث الصفحة وحاول مرة أخرى.'**
  String get bookingAlreadyHandledError;

  /// No description provided for @emptyDefault.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد شيء هنا بعد'**
  String get emptyDefault;

  /// No description provided for @loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل…'**
  String get loading;

  /// No description provided for @cancel.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get cancel;

  /// No description provided for @ok.
  ///
  /// In ar, this message translates to:
  /// **'حسناً'**
  String get ok;

  /// No description provided for @verified.
  ///
  /// In ar, this message translates to:
  /// **'موثّق'**
  String get verified;

  /// No description provided for @currencyLyd.
  ///
  /// In ar, this message translates to:
  /// **'د.ل'**
  String get currencyLyd;

  /// No description provided for @profileTitle.
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// No description provided for @language.
  ///
  /// In ar, this message translates to:
  /// **'اللغة'**
  String get language;

  /// No description provided for @vendorTools.
  ///
  /// In ar, this message translates to:
  /// **'أدوات المورّد'**
  String get vendorTools;

  /// No description provided for @manageAvailability.
  ///
  /// In ar, this message translates to:
  /// **'إدارة التوفر'**
  String get manageAvailability;

  /// No description provided for @editListing.
  ///
  /// In ar, this message translates to:
  /// **'تعديل العرض'**
  String get editListing;

  /// No description provided for @becomeVendor.
  ///
  /// In ar, this message translates to:
  /// **'كن مورّداً'**
  String get becomeVendor;

  /// No description provided for @seeAll.
  ///
  /// In ar, this message translates to:
  /// **'عرض الكل'**
  String get seeAll;

  /// No description provided for @pickDate.
  ///
  /// In ar, this message translates to:
  /// **'اختر التاريخ'**
  String get pickDate;

  /// No description provided for @requiredField.
  ///
  /// In ar, this message translates to:
  /// **'هذا الحقل مطلوب'**
  String get requiredField;

  /// No description provided for @photosLabel.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get photosLabel;

  /// No description provided for @addPhoto.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صورة'**
  String get addPhoto;

  /// No description provided for @photoUploadFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر رفع الصورة'**
  String get photoUploadFailed;

  /// No description provided for @quotedAmountLabel.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المتفق عليه (د.ل)'**
  String get quotedAmountLabel;

  /// No description provided for @quotedAmountHint.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المتفق عليه مع الزوجين'**
  String get quotedAmountHint;

  /// No description provided for @commissionDueLabel.
  ///
  /// In ar, this message translates to:
  /// **'عمولة دهر (10%)'**
  String get commissionDueLabel;

  /// No description provided for @acceptBookingTitle.
  ///
  /// In ar, this message translates to:
  /// **'قبول الحجز'**
  String get acceptBookingTitle;

  /// No description provided for @confirmAccept.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد القبول'**
  String get confirmAccept;

  /// No description provided for @quotedAmountRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً أكبر من صفر'**
  String get quotedAmountRequired;

  /// No description provided for @commissionUnpaid.
  ///
  /// In ar, this message translates to:
  /// **'غير مدفوعة'**
  String get commissionUnpaid;

  /// No description provided for @commissionPaid.
  ///
  /// In ar, this message translates to:
  /// **'مدفوعة'**
  String get commissionPaid;

  /// No description provided for @commissionWaived.
  ///
  /// In ar, this message translates to:
  /// **'معفاة'**
  String get commissionWaived;

  /// No description provided for @unpaidCommissionOwed.
  ///
  /// In ar, this message translates to:
  /// **'رسوم دهر (غير مدفوعة)'**
  String get unpaidCommissionOwed;

  /// No description provided for @noUnpaidCommission.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد رسوم دهر غير مدفوعة'**
  String get noUnpaidCommission;

  /// No description provided for @quotedAmountDisplay.
  ///
  /// In ar, this message translates to:
  /// **'عرض السعر'**
  String get quotedAmountDisplay;

  /// No description provided for @commissionNoteVendor.
  ///
  /// In ar, this message translates to:
  /// **'يسجّل دهر 10٪ من هذا المبلغ. يدفع الزوجان هذه الرسوم لدهر بتحويل بنكي. تُسوّى بقية المبلغ معهم خارج المنصة.'**
  String get commissionNoteVendor;

  /// No description provided for @invalidQuotedAmount.
  ///
  /// In ar, this message translates to:
  /// **'أدخل مبلغاً صالحاً بالدينار الليبي'**
  String get invalidQuotedAmount;

  /// No description provided for @commissionStatusLabel.
  ///
  /// In ar, this message translates to:
  /// **'حالة العمولة'**
  String get commissionStatusLabel;

  /// No description provided for @bookedDatesTitle.
  ///
  /// In ar, this message translates to:
  /// **'التواريخ المحجوزة'**
  String get bookedDatesTitle;

  /// No description provided for @dateUnavailable.
  ///
  /// In ar, this message translates to:
  /// **'هذا التاريخ محجوز'**
  String get dateUnavailable;

  /// No description provided for @noBookedDates.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تواريخ محجوزة'**
  String get noBookedDates;

  /// No description provided for @managePhotos.
  ///
  /// In ar, this message translates to:
  /// **'إدارة الصور'**
  String get managePhotos;

  /// No description provided for @nextBookedDates.
  ///
  /// In ar, this message translates to:
  /// **'أقرب التواريخ المحجوزة'**
  String get nextBookedDates;

  /// No description provided for @noUpcomingBooked.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد تواريخ محجوزة قادمة'**
  String get noUpcomingBooked;

  /// No description provided for @inboxFilterAll.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get inboxFilterAll;

  /// No description provided for @reviewNotCompleted.
  ///
  /// In ar, this message translates to:
  /// **'يمكنك التقييم بعد اكتمال الحجز'**
  String get reviewNotCompleted;

  /// No description provided for @alreadyReviewed.
  ///
  /// In ar, this message translates to:
  /// **'لقد قيّمت هذا الحجز مسبقاً'**
  String get alreadyReviewed;

  /// No description provided for @priceRangeRequired.
  ///
  /// In ar, this message translates to:
  /// **'أدخل نطاق السعر بالدينار الليبي'**
  String get priceRangeRequired;

  /// No description provided for @priceRangeInvalid.
  ///
  /// In ar, this message translates to:
  /// **'يجب أن يكون السعر الأعلى أكبر من أو يساوي السعر الأدنى'**
  String get priceRangeInvalid;

  /// No description provided for @whatsappRequired.
  ///
  /// In ar, this message translates to:
  /// **'رقم واتساب مطلوب'**
  String get whatsappRequired;

  /// No description provided for @invalidWhatsapp.
  ///
  /// In ar, this message translates to:
  /// **'أدخل رقم واتساب ليبي صالح'**
  String get invalidWhatsapp;

  /// No description provided for @descriptionRequired.
  ///
  /// In ar, this message translates to:
  /// **'الوصف مطلوب'**
  String get descriptionRequired;

  /// No description provided for @businessNameRequired.
  ///
  /// In ar, this message translates to:
  /// **'اسم النشاط مطلوب'**
  String get businessNameRequired;

  /// No description provided for @reorderPhotosHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط مع السحب لإعادة الترتيب. الصورة الأولى هي الغلاف.'**
  String get reorderPhotosHint;

  /// No description provided for @deletePhoto.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصورة'**
  String get deletePhoto;

  /// No description provided for @photosEmpty.
  ///
  /// In ar, this message translates to:
  /// **'أضف صوراً لأعمالك'**
  String get photosEmpty;

  /// No description provided for @coverPhoto.
  ///
  /// In ar, this message translates to:
  /// **'الغلاف'**
  String get coverPhoto;

  /// No description provided for @vendorPhotosTitle.
  ///
  /// In ar, this message translates to:
  /// **'المعرض'**
  String get vendorPhotosTitle;

  /// No description provided for @toggleAvailabilityHint.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على تاريخ لتعيينه محجوزاً أو متاحاً'**
  String get toggleAvailabilityHint;

  /// No description provided for @setupVendorListing.
  ///
  /// In ar, this message translates to:
  /// **'أكمل إعداد عرضك'**
  String get setupVendorListing;

  /// No description provided for @bookingDateBookedError.
  ///
  /// In ar, this message translates to:
  /// **'اختر تاريخاً غير محجوز'**
  String get bookingDateBookedError;

  /// No description provided for @photoCountStat.
  ///
  /// In ar, this message translates to:
  /// **'الصور'**
  String get photoCountStat;

  /// No description provided for @privacyPolicy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get termsOfUse;

  /// No description provided for @legalStartingNotice.
  ///
  /// In ar, this message translates to:
  /// **'بيان أوّلي — وليس استشارة قانونية.'**
  String get legalStartingNotice;

  /// No description provided for @deleteAccount.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In ar, this message translates to:
  /// **'حذف حسابك؟'**
  String get deleteAccountTitle;

  /// No description provided for @deleteAccountBody.
  ///
  /// In ar, this message translates to:
  /// **'سيُحذف حساب دهر نهائياً. إذا كنت مورّداً فسيُزال عرضك وصورك. لا يمكن التراجع عن هذا.'**
  String get deleteAccountBody;

  /// No description provided for @deleteAccountConfirm.
  ///
  /// In ar, this message translates to:
  /// **'حذف الحساب'**
  String get deleteAccountConfirm;

  /// No description provided for @deleteAccountFailed.
  ///
  /// In ar, this message translates to:
  /// **'تعذر حذف الحساب. حاول مرة أخرى أو راسل mohammedalariyibi@gmail.com.'**
  String get deleteAccountFailed;

  /// No description provided for @discoverEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مورّدون هنا'**
  String get discoverEmptyTitle;

  /// No description provided for @discoverEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'سيظهر هنا المورّدون المعتمدون في طرابلس وبنغازي.'**
  String get discoverEmptyBody;

  /// No description provided for @discoverEmptyFiltered.
  ///
  /// In ar, this message translates to:
  /// **'لا يوجد مورّدون مطابقون لهذه التصفية. جرّب مدينة أو تصنيفاً أو سعراً آخر.'**
  String get discoverEmptyFiltered;

  /// No description provided for @favoritesEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مفضلات بعد'**
  String get favoritesEmptyTitle;

  /// No description provided for @favoritesEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'احفظ مورّدين من الاكتشاف لتجدهم لاحقاً.'**
  String get favoritesEmptyBody;

  /// No description provided for @browseDiscover.
  ///
  /// In ar, this message translates to:
  /// **'تصفح الاكتشاف'**
  String get browseDiscover;

  /// No description provided for @bookingsEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حجوزات بعد'**
  String get bookingsEmptyTitle;

  /// No description provided for @bookingsEmptyBody.
  ///
  /// In ar, this message translates to:
  /// **'اطلب حجزاً من مورّد في الاكتشاف.'**
  String get bookingsEmptyBody;

  /// No description provided for @inboxEmptyTitle.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات'**
  String get inboxEmptyTitle;

  /// No description provided for @inboxEmptyAll.
  ///
  /// In ar, this message translates to:
  /// **'عندما يطلب الأزواج تاريخاً سيظهر هنا.'**
  String get inboxEmptyAll;

  /// No description provided for @inboxEmptyPending.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات معلّقة. راجع التصفيات الأخرى للحجوزات المقبولة.'**
  String get inboxEmptyPending;

  /// No description provided for @inboxEmptyAccepted.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حجوزات مقبولة في هذه التصفية.'**
  String get inboxEmptyAccepted;

  /// No description provided for @inboxEmptyDeclined.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد طلبات مرفوضة في هذه التصفية.'**
  String get inboxEmptyDeclined;

  /// No description provided for @inboxEmptyCompleted.
  ///
  /// In ar, this message translates to:
  /// **'لا توجد حجوزات مكتملة في هذه التصفية.'**
  String get inboxEmptyCompleted;

  /// No description provided for @acceptQuoteSuccess.
  ///
  /// In ar, this message translates to:
  /// **'تم قبول الحجز. يدفع الزوجان رسوم دهر 10٪ بتحويل بنكي.'**
  String get acceptQuoteSuccess;

  /// No description provided for @roleNotAssignable.
  ///
  /// In ar, this message translates to:
  /// **'اختر زوجين أو مورّداً. لا يمكن تعيين دور المشرف ذاتياً.'**
  String get roleNotAssignable;

  /// No description provided for @bookingDetailTitle.
  ///
  /// In ar, this message translates to:
  /// **'الحجز'**
  String get bookingDetailTitle;

  /// No description provided for @platformFeeTitle.
  ///
  /// In ar, this message translates to:
  /// **'رسوم منصة دهر (10%)'**
  String get platformFeeTitle;

  /// No description provided for @platformFeeBody.
  ///
  /// In ar, this message translates to:
  /// **'حوّل {amount} إلى دهر بتحويل بنكي عبر الإنترنت. هذه رسوم المنصة — وليست دفعاً ببطاقة داخل التطبيق.'**
  String platformFeeBody(String amount);

  /// No description provided for @platformFeeVendorRest.
  ///
  /// In ar, this message translates to:
  /// **'بقية عرض السعر ما زالت تُسوّى مع المورّد خارج المنصة (غالباً واتساب).'**
  String get platformFeeVendorRest;

  /// No description provided for @bankDetailsTitle.
  ///
  /// In ar, this message translates to:
  /// **'بيانات بنك دهر'**
  String get bankDetailsTitle;

  /// No description provided for @bankDetailsPending.
  ///
  /// In ar, this message translates to:
  /// **'بيانات البنك ستأتي من التشغيل.'**
  String get bankDetailsPending;

  /// No description provided for @bankNameLabel.
  ///
  /// In ar, this message translates to:
  /// **'البنك'**
  String get bankNameLabel;

  /// No description provided for @accountHolderLabel.
  ///
  /// In ar, this message translates to:
  /// **'صاحب الحساب'**
  String get accountHolderLabel;

  /// No description provided for @accountNumberLabel.
  ///
  /// In ar, this message translates to:
  /// **'رقم الحساب / IBAN'**
  String get accountNumberLabel;

  /// No description provided for @transferNoteLabel.
  ///
  /// In ar, this message translates to:
  /// **'مرجع التحويل'**
  String get transferNoteLabel;

  /// No description provided for @transferNoteHint.
  ///
  /// In ar, this message translates to:
  /// **'مرجع البنك أو ملاحظة قصيرة'**
  String get transferNoteHint;

  /// No description provided for @iTransferred.
  ///
  /// In ar, this message translates to:
  /// **'حوّلت المبلغ'**
  String get iTransferred;

  /// No description provided for @transferReported.
  ///
  /// In ar, this message translates to:
  /// **'أُرسلت ملاحظة التحويل. سيؤكّد دهر بعد وصول المبلغ.'**
  String get transferReported;

  /// No description provided for @transferNoteRequired.
  ///
  /// In ar, this message translates to:
  /// **'أضف مرجعاً قصيراً للتحويل'**
  String get transferNoteRequired;

  /// No description provided for @vendorDahrFeeStatus.
  ///
  /// In ar, this message translates to:
  /// **'حالة رسوم دهر'**
  String get vendorDahrFeeStatus;

  /// No description provided for @vendorDahrFeeHint.
  ///
  /// In ar, this message translates to:
  /// **'للحالة فقط. يدفع الزوجان رسوم 10٪ لدهر بتحويل بنكي.'**
  String get vendorDahrFeeHint;

  /// No description provided for @guestCountInvalid.
  ///
  /// In ar, this message translates to:
  /// **'عدد الضيوف يجب أن يكون 1 على الأقل'**
  String get guestCountInvalid;

  /// No description provided for @messageTooLong.
  ///
  /// In ar, this message translates to:
  /// **'الرسالة طويلة جداً'**
  String get messageTooLong;

  /// No description provided for @ratingRequired.
  ///
  /// In ar, this message translates to:
  /// **'اختر تقييماً من 1 إلى 5'**
  String get ratingRequired;

  /// No description provided for @commentTooLong.
  ///
  /// In ar, this message translates to:
  /// **'التعليق طويل جداً'**
  String get commentTooLong;

  /// No description provided for @editProfile.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف'**
  String get editProfile;

  /// No description provided for @phoneForWhatsappHint.
  ///
  /// In ar, this message translates to:
  /// **'يستخدم المورّد هذا الرقم للتواصل عبر واتساب حول الحجز. لا يُستخدم لتسجيل الدخول.'**
  String get phoneForWhatsappHint;

  /// No description provided for @coupleContactUnknown.
  ///
  /// In ar, this message translates to:
  /// **'الزوجان'**
  String get coupleContactUnknown;

  /// No description provided for @reportReview.
  ///
  /// In ar, this message translates to:
  /// **'الإبلاغ عن التقييم'**
  String get reportReview;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
