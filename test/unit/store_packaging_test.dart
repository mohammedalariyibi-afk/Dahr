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
}
