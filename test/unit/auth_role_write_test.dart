import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/security/auth_role_write.dart';

void main() {
  group('AuthRoleWrite', () {
    test('allows consumer and vendor only', () {
      expect(AuthRoleWrite.isAssignable(UserRole.consumer), isTrue);
      expect(AuthRoleWrite.isAssignable(UserRole.vendor), isTrue);
      expect(AuthRoleWrite.isAssignable(UserRole.admin), isFalse);
    });

    test('upsert payload never includes admin', () {
      expect(
        AuthRoleWrite.upsertPayload(userId: 'u1', role: UserRole.vendor),
        {'id': 'u1', 'role': 'vendor'},
      );
      expect(
        () => AuthRoleWrite.upsertPayload(userId: 'u1', role: UserRole.admin),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'role_not_assignable',
          ),
        ),
      );
    });
  });
}
