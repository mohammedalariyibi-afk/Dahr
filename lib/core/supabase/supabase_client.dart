import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract final class DahrSupabase {
  static Future<void> initialize() async {
    final url = dotenv.env['SUPABASE_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';
    if (url.isEmpty ||
        anonKey.isEmpty ||
        anonKey == 'your-local-anon-key') {
      throw StateError(
        'Missing or placeholder SUPABASE_URL / SUPABASE_ANON_KEY. '
        'Copy .env.example to .env and set local/new-project values '
        '(do not use the Zeen project).',
      );
    }
    await Supabase.initialize(url: url, publishableKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;

  static GoTrueClient get auth => client.auth;

  static User? get currentUser => auth.currentUser;

  static String? get currentUserId => currentUser?.id;
}
