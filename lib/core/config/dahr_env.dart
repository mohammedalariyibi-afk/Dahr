import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dahr_env_rules.dart';

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

  static const dahrLyProjectRef = DahrEnvRules.dahrLyProjectRef;
  static const dahrLyHost = DahrEnvRules.dahrLyHost;
  static const dahrLyUrl = DahrEnvRules.dahrLyUrl;
  static const placeholderKeys = DahrEnvRules.placeholderKeys;

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

  static String firstNonEmpty(Iterable<String?> values) =>
      DahrEnvRules.firstNonEmpty(values);

  static String resolveUrl({
    required Map<String, String?> env,
    String dartUrl = '',
  }) =>
      DahrEnvRules.resolveUrl(env: env, dartUrl: dartUrl);

  static String resolveAnonKey({
    required Map<String, String?> env,
    String dartAnonKey = '',
    String dartPublishableKey = '',
  }) =>
      DahrEnvRules.resolveAnonKey(
        env: env,
        dartAnonKey: dartAnonKey,
        dartPublishableKey: dartPublishableKey,
      );

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
  }) =>
      DahrEnvRules.isMissingOrPlaceholder(url: url, anonKey: anonKey);

  /// HTTPS required except loopback (local `supabase start` / emulator).
  static bool isAllowedSupabaseUrl(String url) =>
      DahrEnvRules.isAllowedSupabaseUrl(url);

  /// True for a service_role / secret key that must never ship in the app.
  static bool looksLikeSecretKey(String key) =>
      DahrEnvRules.looksLikeSecretKey(key);

  /// Store / Play AAB builds must target live Dahr LY over HTTPS.
  static bool isDahrLyStoreUrl(String url) =>
      DahrEnvRules.isDahrLyStoreUrl(url);

  /// Non-null reason a `.env` / dart-define file must not be used for a
  /// store build. Runtime [isAllowedSupabaseUrl] still allows loopback for
  /// local `flutter run --release`.
  static String? storeReleaseBlocker({
    required String url,
    required String anonKey,
  }) =>
      DahrEnvRules.storeReleaseBlocker(url: url, anonKey: anonKey);
}
