// Store / Play AAB preflight. Reads a dart-define-from-file `.env` and
// refuses missing, placeholder, wrong-project, or service_role keys.
//
//   dart run tool/check_store_env.dart
//   dart run tool/check_store_env.dart path/to/.env
//
// Does not print key material.

import 'dart:convert';
import 'dart:io';

import 'package:dahr/core/config/dahr_env_rules.dart';

void main(List<String> args) {
  final envPath = args.isEmpty ? '.env' : args.first;
  final file = File(envPath);
  if (!file.existsSync()) {
    stderr.writeln(
      'Store preflight: $envPath is missing. Copy .env.example to .env, '
      'set SUPABASE_URL=${DahrEnvRules.dahrLyUrl} and the Dahr LY anon / '
      'publishable key, then rebuild with --dart-define-from-file=.env.',
    );
    exit(1);
  }

  final env = parseDotEnv(file.readAsStringSync());
  final url = DahrEnvRules.resolveUrl(env: env);
  final anonKey = DahrEnvRules.resolveAnonKey(env: env);
  final blocker = DahrEnvRules.storeReleaseBlocker(url: url, anonKey: anonKey);
  if (blocker != null) {
    stderr.writeln('Store preflight: $blocker');
    stderr.writeln('File: $envPath');
    exit(1);
  }

  stdout.writeln(
    'Store preflight OK: $envPath targets Dahr LY '
    '(${DahrEnvRules.dahrLyProjectRef}).',
  );
}

Map<String, String> parseDotEnv(String contents) {
  final out = <String, String>{};
  for (final raw in LineSplitter.split(contents)) {
    var line = raw.trim();
    if (line.isEmpty || line.startsWith('#')) continue;
    if (line.startsWith('export ')) {
      line = line.substring(7).trimLeft();
    }
    final eq = line.indexOf('=');
    if (eq <= 0) continue;
    final key = line.substring(0, eq).trim();
    var value = line.substring(eq + 1).trim();
    if (value.length >= 2) {
      final quote = value[0];
      if ((quote == '"' || quote == "'") && value.endsWith(quote)) {
        value = value.substring(1, value.length - 1);
      }
    }
    out[key] = value;
  }
  return out;
}
