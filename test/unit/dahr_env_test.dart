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

  group('DahrEnv store release preflight', () {
    const anonJwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
        'eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIn0.sig';

    test('accepts Dahr LY https URL with a non-placeholder anon key', () {
      expect(
        DahrEnv.isDahrLyStoreUrl(DahrEnv.dahrLyUrl),
        isTrue,
      );
      expect(
        DahrEnv.storeReleaseBlocker(
          url: DahrEnv.dahrLyUrl,
          anonKey: anonJwt,
        ),
        isNull,
      );
    });

    test('rejects placeholders, loopback, other projects, and service_role', () {
      expect(
        DahrEnv.storeReleaseBlocker(
          url: DahrEnv.dahrLyUrl,
          anonKey: 'your-local-anon-key',
        ),
        contains('placeholder'),
      );
      expect(
        DahrEnv.storeReleaseBlocker(
          url: 'http://127.0.0.1:54321',
          anonKey: anonJwt,
        ),
        contains(DahrEnv.dahrLyUrl),
      );
      expect(
        DahrEnv.storeReleaseBlocker(
          url: 'https://zeen.supabase.co',
          anonKey: anonJwt,
        ),
        contains(DahrEnv.dahrLyProjectRef),
      );
      expect(
        DahrEnv.storeReleaseBlocker(
          url: 'http://cccusktgxrizfwpixddu.supabase.co',
          anonKey: anonJwt,
        ),
        isNotNull,
      );
      const header = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9';
      final payload = base64Url.encode(
        utf8.encode('{"role":"service_role","iss":"supabase"}'),
      );
      expect(
        DahrEnv.storeReleaseBlocker(
          url: DahrEnv.dahrLyUrl,
          anonKey: '$header.$payload.sig',
        ),
        contains('service_role'),
      );
    });

    test('store script rejects .env.example and a missing file', () async {
      final example = await Process.run(
        'dart',
        ['run', 'tool/check_store_env.dart', '.env.example'],
      );
      expect(example.exitCode, isNot(0), reason: example.stderr.toString());
      expect(example.stderr.toString(), contains('placeholder'));

      final missing = await Process.run(
        'dart',
        [
          'run',
          'tool/check_store_env.dart',
          'tool/.missing-store-env-for-test',
        ],
      );
      expect(missing.exitCode, isNot(0));
      expect(missing.stderr.toString(), contains('missing'));
    });

    test('store script accepts a Dahr LY dart-define file', () async {
      final file = File('tool/.tmp-store-env-ok');
      addTearDown(() {
        if (file.existsSync()) file.deleteSync();
      });
      file.writeAsStringSync(
        'SUPABASE_URL=${DahrEnv.dahrLyUrl}\n'
        'SUPABASE_ANON_KEY=$anonJwt\n',
      );
      final result = await Process.run(
        'dart',
        ['run', 'tool/check_store_env.dart', file.path],
      );
      expect(
        result.exitCode,
        0,
        reason: 'stdout=${result.stdout} stderr=${result.stderr}'
            .replaceAll(RegExp(r'\s+'), ' '),
      );
      expect(result.stdout.toString(), contains(DahrEnv.dahrLyProjectRef));
    });
  });
}
