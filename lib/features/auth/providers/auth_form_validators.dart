import '../../../core/constants/app_constants.dart';

/// Pure helpers for auth form validation (unit/widget tested).
abstract final class AuthFormValidators {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (!AppConstants.isValidLibyaPhone(value)) return 'invalid_phone';
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (!AppConstants.isValidEmail(value)) return 'invalid_email';
    return null;
  }

  static String? validateOtp(String? value) {
    if (value == null || value.trim().isEmpty) return 'required';
    if (!RegExp(r'^\d{6}$').hasMatch(value.trim())) return 'invalid_otp';
    return null;
  }

  static String normalizePhoneInput(String value) =>
      AppConstants.normalizeLibyaPhone(value);

  static String toE164(String value) => AppConstants.toE164Libya(value);
}
