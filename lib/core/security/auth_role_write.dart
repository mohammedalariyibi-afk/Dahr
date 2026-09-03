import '../models/enums.dart';

/// Client-side role writes. Admin is never self-assigned.
///
/// The Flutter app must not treat `profiles.role` as a source of privilege
/// beyond UX (inbox vs bookings). Live RLS still has to reject `admin`.
abstract final class AuthRoleWrite {
  static const Set<UserRole> assignable = {
    UserRole.consumer,
    UserRole.vendor,
  };

  static bool isAssignable(UserRole role) => assignable.contains(role);

  /// Throws [StateError] `role_not_assignable` for admin or unknown values.
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
