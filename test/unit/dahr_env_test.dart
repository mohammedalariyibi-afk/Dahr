import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/config/dahr_env.dart';

void main() {
  group('DahrEnv.resolveUrl', () {
    test('prefers dart-define over dotenv', () {
      expect(
        DahrEnv.resolveUrl(
          dartUrl: 'https://cccusktgxrizfwpixddu.supabase.co',
          env: {'SUPABASE_URL': 'http://127.0.0.1:54321'},
        ),
        'https://cccusktgxrizfwpixddu.supabase.co',
      );
    });

    test('falls back to SUPABASE_URL from dotenv', () {
      expect(
        DahrEnv.resolveUrl(
          env: {'SUPABASE_URL': 'http://127.0.0.1:54321'},
        ),
        'http://127.0.0.1:54321',
      );
    });
  });

  group('DahrEnv.resolveAnonKey', () {
    test('accepts SUPABASE_ANON_KEY, then publishable alias', () {
      expect(
        DahrEnv.resolveAnonKey(
          env: {'SUPABASE_ANON_KEY': 'anon-from-file'},
        ),
        'anon-from-file',
      );
      expect(
        DahrEnv.resolveAnonKey(
          env: {'SUPABASE_PUBLISHABLE_KEY': 'publishable-from-file'},
        ),
        'publishable-from-file',
      );
      expect(
        DahrEnv.resolveAnonKey(
          dartPublishableKey: 'from-define',
          env: {'SUPABASE_ANON_KEY': 'from-file'},
        ),
        'from-define',
      );
    });

    test('dart-define anon key wins over publishable alias', () {
      expect(
        DahrEnv.resolveAnonKey(
          dartAnonKey: 'anon-define',
          dartPublishableKey: 'pub-define',
          env: {
            'SUPABASE_ANON_KEY': 'anon-file',
            'SUPABASE_PUBLISHABLE_KEY': 'pub-file',
          },
        ),
        'anon-define',
      );
    });
  });

  group('DahrEnv.isMissingOrPlaceholder', () {
    test('rejects empty url and placeholder keys', () {
      expect(
        DahrEnv.isMissingOrPlaceholder(
          url: '',
          anonKey: 'real-key',
        ),
        isTrue,
      );
      expect(
        DahrEnv.isMissingOrPlaceholder(
          url: 'http://127.0.0.1:54321',
          anonKey: 'your-local-anon-key',
        ),
        isTrue,
      );
      expect(
        DahrEnv.isMissingOrPlaceholder(
          url: 'http://127.0.0.1:54321',
          anonKey: 'your-publishable-key',
        ),
        isTrue,
      );
      expect(
        DahrEnv.isMissingOrPlaceholder(
          url: 'http://127.0.0.1:54321',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.local',
        ),
        isFalse,
      );
    });
  });

  test('.env.example lists the keys Flutter actually reads', () {
    final contents = File('.env.example').readAsStringSync();
    dotenv.testLoad(fileInput: contents);
    expect(dotenv.env['SUPABASE_URL'], 'http://127.0.0.1:54321');
    expect(dotenv.env['SUPABASE_ANON_KEY'], 'your-local-anon-key');
    expect(contents.contains('SUPABASE_PUBLISHABLE_KEY'), isTrue);
    expect(contents.contains('cccusktgxrizfwpixddu'), isTrue);
    expect(
      DahrEnv.isMissingOrPlaceholder(
        url: dotenv.env['SUPABASE_URL']!,
        anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      ),
      isTrue,
    );
  });

  group('DahrEnv URL and key safety', () {
    test('allows https cloud and loopback http only', () {
      expect(
        DahrEnv.isAllowedSupabaseUrl('https://cccusktgxrizfwpixddu.supabase.co'),
        isTrue,
      );
      expect(DahrEnv.isAllowedSupabaseUrl('http://127.0.0.1:54321'), isTrue);
      expect(DahrEnv.isAllowedSupabaseUrl('http://10.0.2.2:54321'), isTrue);
      expect(
        DahrEnv.isAllowedSupabaseUrl('http://cccusktgxrizfwpixddu.supabase.co'),
        isFalse,
      );
      expect(DahrEnv.isAllowedSupabaseUrl('ftp://127.0.0.1'), isFalse);
    });

    test('rejects service_role JWTs and sb_secret keys', () {
      expect(DahrEnv.looksLikeSecretKey('sb_secret_abc'), isTrue);
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final payload = base64Url.encode(
        utf8.encode('{"role":"service_role","iss":"supabase"}'),
      );
      expect(DahrEnv.looksLikeSecretKey('$header.$payload.sig'), isTrue);
      expect(DahrEnv.looksLikeSecretKey('anon-not-a-jwt'), isFalse);
    });
  });
}
