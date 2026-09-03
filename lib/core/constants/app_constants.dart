abstract final class AppConstants {
  static const String appName = 'Dahr';
  static const String currencyCode = 'LYD';
  static const String phoneCountryCode = '+218';
  static const String defaultLocale = 'ar';
  static const String englishLocale = 'en';
  static const String supportEmail = 'mohammedalariyibi@gmail.com';
  static const String privacyPath = '/legal/privacy';
  static const String termsPath = '/legal/terms';
  static const String publicPrivacyPath = '/privacy';
  static const String publicTermsPath = '/terms';

  /// Libya mobile: after +218, typically 9 digits starting with 9.
  static const int libyaLocalPhoneLength = 9;

  static const List<String> supportedLocales = [defaultLocale, englishLocale];

  static String formatPrice(num? value) {
    if (value == null) return '—';
    final fixed = value % 1 == 0 ? value.toInt().toString() : value.toStringAsFixed(2);
    return '$fixed $currencyCode';
  }

  static String formatPriceRange(num? min, num? max) {
    if (min == null && max == null) return '—';
    if (min != null && max != null) {
      return '${formatPrice(min)} – ${formatPrice(max)}';
    }
    return formatPrice(min ?? max);
  }

  /// Builds a WhatsApp deep link (wa.me).
  static String whatsappUrl(String rawNumber, {String? message}) {
    final digits = rawNumber.replaceAll(RegExp(r'[^\d]'), '');
    final uri = Uri(
      scheme: 'https',
      host: 'wa.me',
      path: digits,
      queryParameters: message != null && message.isNotEmpty
          ? {'text': message}
          : null,
    );
    return uri.toString();
  }

  static String normalizeLibyaPhone(String input) {
    var digits = input.replaceAll(RegExp(r'[^\d+]'), '');
    if (digits.startsWith('+218')) {
      digits = digits.substring(4);
    } else if (digits.startsWith('218')) {
      digits = digits.substring(3);
    } else if (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits;
  }

  static String toE164Libya(String localDigits) {
    final local = normalizeLibyaPhone(localDigits);
    return '$phoneCountryCode$local';
  }

  static bool isValidLibyaPhone(String input) {
    final local = normalizeLibyaPhone(input);
    return RegExp(r'^9\d{8}$').hasMatch(local);
  }

  static bool isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());
  }
}
