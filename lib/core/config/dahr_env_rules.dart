import 'dart:convert';

/// Flutter-free env rules so `dart run tool/check_store_env.dart` can share
/// the same checks as [DahrEnv] without pulling `dart:ui`.
abstract final class DahrEnvRules {
  static const dahrLyProjectRef = 'cccusktgxrizfwpixddu';
  static const dahrLyHost = 'cccusktgxrizfwpixddu.supabase.co';
  static const dahrLyUrl = 'https://cccusktgxrizfwpixddu.supabase.co';

  static const placeholderKeys = {
    '',
    'your-local-anon-key',
    'your-anon-key',
    'your-publishable-key',
    '<Project Settings → API → anon / publishable key>',
  };

  static String firstNonEmpty(Iterable<String?> values) {
    for (final value in values) {
      if (value == null) continue;
      final trimmed = value.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return '';
  }

  static String resolveUrl({
    required Map<String, String?> env,
    String dartUrl = '',
  }) {
    return firstNonEmpty([
      dartUrl,
      env['SUPABASE_URL'],
    ]);
  }

  static String resolveAnonKey({
    required Map<String, String?> env,
    String dartAnonKey = '',
    String dartPublishableKey = '',
  }) {
    return firstNonEmpty([
      dartAnonKey,
      dartPublishableKey,
      env['SUPABASE_ANON_KEY'],
      env['SUPABASE_PUBLISHABLE_KEY'],
    ]);
  }

  static bool isMissingOrPlaceholder({
    required String url,
    required String anonKey,
  }) {
    if (url.trim().isEmpty) return true;
    return placeholderKeys.contains(anonKey.trim());
  }

  /// HTTPS required except loopback (local `supabase start` / emulator).
  static bool isAllowedSupabaseUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.host.isEmpty) return false;
    if (uri.scheme == 'https') return true;
    if (uri.scheme != 'http') return false;
    return uri.host == '127.0.0.1' ||
        uri.host == 'localhost' ||
        uri.host == '10.0.2.2';
  }

  /// True for a service_role / secret key that must never ship in the app.
  static bool looksLikeSecretKey(String key) {
    final trimmed = key.trim();
    if (trimmed.startsWith('sb_secret_') ||
        trimmed.startsWith('sb_service_')) {
      return true;
    }
    final parts = trimmed.split('.');
    if (parts.length != 3) return false;
    try {
      final normalized = base64Url.normalize(parts[1]);
      final payload = utf8.decode(base64Url.decode(normalized));
      return payload.contains('"role":"service_role"') ||
          payload.contains('"role": "service_role"');
    } catch (_) {
      return false;
    }
  }

  /// Store / Play AAB builds must target live Dahr LY over HTTPS.
  static bool isDahrLyStoreUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != 'https') return false;
    if (uri.host.toLowerCase() != dahrLyHost) return false;
    final path = uri.path.replaceAll(RegExp(r'/+$'), '');
    if (path.isNotEmpty) return false;
    if (uri.hasQuery || uri.fragment.isNotEmpty) return false;
    return true;
  }

  /// Non-null reason a `.env` / dart-define file must not be used for a
  /// store build. Runtime [isAllowedSupabaseUrl] still allows loopback for
  /// local `flutter run --release`.
  static String? storeReleaseBlocker({
    required String url,
    required String anonKey,
  }) {
    final trimmedUrl = url.trim();
    final trimmedKey = anonKey.trim();
    if (isMissingOrPlaceholder(url: trimmedUrl, anonKey: trimmedKey)) {
      return 'Missing or placeholder SUPABASE_URL / SUPABASE_ANON_KEY '
          '(alias SUPABASE_PUBLISHABLE_KEY). Copy .env.example to .env and '
          'set the Dahr LY anon / publishable key.';
    }
    if (looksLikeSecretKey(trimmedKey)) {
      return 'SUPABASE_ANON_KEY looks like a secret/service_role key. '
          'Use the anon / publishable key only.';
    }
    if (!isDahrLyStoreUrl(trimmedUrl)) {
      return 'Store builds must use $dahrLyUrl '
          '(project $dahrLyProjectRef). Do not use Zeen, local supabase, '
          'or another project.';
    }
    return null;
  }
}
