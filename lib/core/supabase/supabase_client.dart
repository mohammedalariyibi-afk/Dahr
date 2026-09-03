import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/dahr_env.dart';

abstract final class DahrSupabase {
  static Future<void> initialize() async {
    await DahrEnv.load();
    final url = DahrEnv.supabaseUrl;
    final anonKey = DahrEnv.supabaseAnonKey;
    if (DahrEnv.isMissingOrPlaceholder(url: url, anonKey: anonKey)) {
      throw StateError(
        'Missing or placeholder SUPABASE_URL / SUPABASE_ANON_KEY '
        '(alias SUPABASE_PUBLISHABLE_KEY). '
        'Copy .env.example to .env and run with '
        '--dart-define-from-file=.env, or pass the same names as dart-define. '
        'Use local `supabase start` or the Dahr LY project — do not use Zeen.',
      );
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static String? get currentUserId => currentUser?.id;
}
