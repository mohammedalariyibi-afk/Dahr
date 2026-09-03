import 'enums.dart';

/// Roles the Flutter client may write to `profiles.role`.
///
/// Admin is never self-assigned. Live Dahr LY rejects `role = admin` on
/// insert/update for non-admins; this guard keeps the app from sending it.
abstract final class ProfileRoleWrite {
  static const Set<UserRole> assignable = {
    UserRole.consumer,
    UserRole.vendor,
  };

  static bool isAssignable(UserRole role) => assignable.contains(role);

  /// Throws [StateError] `role_not_assignable` for admin or any other value.
  static void assertAssignable(UserRole role) {
    if (!isAssignable(role)) {
      throw StateError('role_not_assignable');
    }
  }

  static Map<String, dynamic> upsertPayload({
    required String userId,
    required UserRole role,
  }) {
    assertAssignable(role);
    return {
      'id': userId,
      'role': role.name,
    };
  }
}

/// Onboarding choices shown on role pick. Never includes [UserRole.admin].
abstract final class RoleSelectOptions {
  static const List<UserRole> choices = [
    UserRole.consumer,
    UserRole.vendor,
  ];
}
