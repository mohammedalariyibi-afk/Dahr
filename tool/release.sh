#!/usr/bin/env bash
# Play AAB for Dahr. Fail-closed: requires android/key.properties, then
# store env preflight, then a release appbundle. Never enables debug
# signing for release (that hatch is local flutter run --release only).
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$root"

if [[ ! -f android/key.properties ]]; then
  echo "error: android/key.properties is missing." >&2
  echo "Copy android/key.properties.example to android/key.properties and fill" >&2
  echo "storeFile, storePassword, keyAlias, and keyPassword. See STORE.md Signing." >&2
  exit 1
fi

dart run tool/check_store_env.dart
flutter build appbundle --release --dart-define-from-file=.env
