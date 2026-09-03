import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

const _localeKey = 'dahr_locale';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final localeProvider =
    StateNotifierProvider<LocaleController, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleController(prefs);
});

class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._prefs)
      : super(Locale(_prefs.getString(_localeKey) ?? AppConstants.defaultLocale));

  final SharedPreferences _prefs;

  bool get isArabic => state.languageCode == AppConstants.defaultLocale;

  Future<void> setLocale(String languageCode) async {
    if (!AppConstants.supportedLocales.contains(languageCode)) return;
    await _prefs.setString(_localeKey, languageCode);
    state = Locale(languageCode);
  }

  Future<void> toggle() async {
    await setLocale(
      isArabic ? AppConstants.englishLocale : AppConstants.defaultLocale,
    );
  }
}
