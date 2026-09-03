import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Session + PKCE storage. Encrypted on Android/iOS; SharedPreferences
/// fallback on desktop/CI where the OS keystore is not available.
abstract final class DahrSessionStorage {
  static bool get useSecureStore {
    if (kIsWeb) return false;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return true;
      default:
        return false;
    }
  }

  static String persistSessionKeyFor(String url) {
    final host = Uri.parse(url).host.split('.').first;
    return 'sb-$host-auth-token';
  }

  static LocalStorage localStorageFor(String url) {
    if (useSecureStore) return const _SecureLocalStorage();
    return SharedPreferencesLocalStorage(
      persistSessionKey: persistSessionKeyFor(url),
    );
  }

  static GotrueAsyncStorage pkceStorage() {
    if (useSecureStore) return const _SecureGotrueAsyncStorage();
    return SharedPreferencesGotrueAsyncStorage();
  }
}

class _SecureLocalStorage extends LocalStorage {
  const _SecureLocalStorage();

  static const _sessionKey = 'dahr_supabase_session';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return (await accessToken()) != null;
  }

  @override
  Future<String?> accessToken() {
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() {
    return _storage.delete(key: _sessionKey);
  }
}

class _SecureGotrueAsyncStorage extends GotrueAsyncStorage {
  const _SecureGotrueAsyncStorage();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  @override
  Future<String?> getItem({required String key}) {
    return _storage.read(key: key);
  }

  @override
  Future<void> removeItem({required String key}) {
    return _storage.delete(key: key);
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return _storage.write(key: key, value: value);
  }
}
