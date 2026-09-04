import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pubspec.lock is tracked and not gitignored', () async {
    expect(File('pubspec.lock').existsSync(), isTrue);
    final ignore = await Process.run('git', [
      'check-ignore',
      '-q',
      'pubspec.lock',
    ]);
    expect(
      ignore.exitCode,
      1,
      reason: 'git check-ignore must not match pubspec.lock',
    );
  });

  test('iOS project is iPhone-only', () {
    final pbx = File('ios/Runner.xcodeproj/project.pbxproj').readAsStringSync();
    expect(pbx.contains('TARGETED_DEVICE_FAMILY = "1,2"'), isFalse);
    expect(
      RegExp(r'TARGETED_DEVICE_FAMILY = 1;').allMatches(pbx).length,
      3,
    );
  });

  test('key.properties.example is committed without secrets', () {
    final example = File('android/key.properties.example').readAsStringSync();
    expect(example, contains('storeFile='));
    expect(example, contains('keyAlias=dahr'));
    expect(example.contains('dahr-upload.jks'), isTrue);
    expect(File('android/key.properties').existsSync(), isFalse);
  });

  test('Android release signing is fail-closed', () {
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('allowDebugReleaseSigning'));
    expect(gradle, contains('key.properties.example'));
    expect(gradle, contains('STORE.md Signing'));
    expect(gradle, isNot(contains('release falls back to debug')));
    expect(
      gradle,
      isNot(contains('otherwise debug signing')),
    );
    // Debug signing is only the local escape hatch, never the missing-file default.
    expect(gradle, contains('signingConfigs.getByName("debug")'));
    expect(gradle, contains('else if (allowDebugReleaseSigning)'));
  });

  test('tool/release.sh is the Play AAB path and never allows debug signing',
      () async {
    final scriptFile = File('tool/release.sh');
    expect(scriptFile.existsSync(), isTrue);
    final executable = await Process.run('test', ['-x', scriptFile.path]);
    expect(executable.exitCode, 0, reason: 'tool/release.sh must be executable');
    final script = scriptFile.readAsStringSync();
    expect(script, contains('android/key.properties'));
    expect(script, contains('dart run tool/check_store_env.dart'));
    expect(
      script,
      contains('flutter build appbundle --release --dart-define-from-file=.env'),
    );
    final commands = script
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('#'))
        .join('\n');
    expect(commands, isNot(contains('allowDebugReleaseSigning')));
  });

  test('store docs describe fail-closed Android signing', () {
    final store = File('STORE.md').readAsStringSync();
    expect(store, contains('./tool/release.sh'));
    expect(store, contains('fail-closed'));
    expect(store, contains('-PallowDebugReleaseSigning=true'));
    expect(store, isNot(contains('release still uses debug signing')));
    expect(
      store,
      isNot(contains('release uses debug signing so local')),
    );

    final checklist = File('docs/store-submit-checklist.md').readAsStringSync();
    expect(checklist, contains('./tool/release.sh'));
    expect(checklist, contains('fail-closed'));
    expect(checklist, contains('-PallowDebugReleaseSigning=true'));

    final readme = File('README.md').readAsStringSync();
    expect(readme, contains('./tool/release.sh'));
    expect(readme, contains('fail-closes'));
    expect(
      readme,
      isNot(contains('otherwise debug signing so `flutter run --release`')),
    );
  });
}
