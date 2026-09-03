import '../../../core/constants/app_constants.dart';

/// Consumer/vendor app sign-in is Email OTP only (no SMS path).
abstract final class AuthLoginSpec {
  static const primaryChannel = 'email';
  static const supportsPhoneOtp = false;

  static String otpChannel({String? requested}) {
    if (supportsPhoneOtp && requested == 'phone') return 'phone';
    return primaryChannel;
  }

  static bool usesPhoneOtp(String? channel) =>
      supportsPhoneOtp && channel == 'phone';

  static Map<String, String> otpExtra({
    required String email,
    String? returnTo,
  }) {
    return {
      'channel': primaryChannel,
      'destination': email,
      if (returnTo != null && returnTo.isNotEmpty) 'returnTo': returnTo,
    };
  }
}

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
