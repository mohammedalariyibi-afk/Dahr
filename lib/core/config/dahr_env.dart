import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Resolves Supabase credentials for Flutter.
///
/// Precedence (first non-empty wins):
/// 1. `--dart-define` / `--dart-define-from-file=.env`
/// 2. `flutter_dotenv` from the bundled `.env.example` asset
///
/// Names: `SUPABASE_URL` plus `SUPABASE_ANON_KEY` or alias
/// `SUPABASE_PUBLISHABLE_KEY` (same publishable/anon key;
/// supabase_flutter `initialize(publishableKey:)`).
abstract final class DahrEnv {
  static const compileTimeUrl = String.fromEnvironment('SUPABASE_URL');
  static const compileTimeAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const compileTimePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  static const placeholderKeys = {
    '',
    'your-local-anon-key',
    'your-anon-key',
    'your-publishable-key',
  };

  static const envExampleAsset = '.env.example';

  /// Loads committed placeholders so [dotenv] is initialized. Real keys should
  /// come from `--dart-define-from-file=.env` (preferred) or by overriding
  /// values in a local copy of the example file.
  static Future<void> load() async {
    await dotenv.load(fileName: envExampleAsset, isOptional: true);
  }

  static Map<String, String> get _dotenvMap {
    if (!dotenv.isInitialized) return const {};
    return dotenv.env;
  }

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

  static String get supabaseUrl => resolveUrl(
        env: _dotenvMap,
        dartUrl: compileTimeUrl,
      );

  static String get supabaseAnonKey => resolveAnonKey(
        env: _dotenvMap,
        dartAnonKey: compileTimeAnonKey,
        dartPublishableKey: compileTimePublishableKey,
      );

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
}
