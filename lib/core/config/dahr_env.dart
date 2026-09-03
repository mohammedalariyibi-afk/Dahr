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
}
