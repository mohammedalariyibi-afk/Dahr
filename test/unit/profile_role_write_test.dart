import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/profile_role_write.dart';

void main() {
  group('ProfileRoleWrite', () {
    test('allows consumer and vendor only', () {
      expect(ProfileRoleWrite.isAssignable(UserRole.consumer), isTrue);
      expect(ProfileRoleWrite.isAssignable(UserRole.vendor), isTrue);
      expect(ProfileRoleWrite.isAssignable(UserRole.admin), isFalse);
      expect(UserRole.admin.isClientAssignable, isFalse);
    });

    test('role pick choices never include admin', () {
      expect(RoleSelectOptions.choices, [UserRole.consumer, UserRole.vendor]);
      expect(RoleSelectOptions.choices.contains(UserRole.admin), isFalse);
    });

    test('upsert payload never includes admin', () {
      expect(
        ProfileRoleWrite.upsertPayload(userId: 'u1', role: UserRole.vendor),
        {'id': 'u1', 'role': 'vendor'},
      );
      expect(
        ProfileRoleWrite.upsertPayload(userId: 'u1', role: UserRole.consumer),
        {'id': 'u1', 'role': 'consumer'},
      );
      expect(
        () => ProfileRoleWrite.upsertPayload(userId: 'u1', role: UserRole.admin),
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
