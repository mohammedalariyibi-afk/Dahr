/// Contract for the `delete_own_account` SECURITY DEFINER RPC.
///
/// The SQL takes **no user-id argument**. PostgREST therefore cannot be asked
/// to delete someone else; the function reads `auth.uid()` only.
/// Keep in sync with `supabase/migrations/20260903140000_delete_own_account.sql`.
abstract final class DeleteAccountRpcSpec {
  static const String rpcName = 'delete_own_account';

  /// Empty: the RPC has no parameters.
  static const List<String> argumentNames = [];

  static const bool securityDefiner = true;

  /// Roles that receive EXECUTE.
  static const List<String> executeRoles = ['authenticated'];

  /// Roles that must not be able to call the RPC (anon has the public API key).
  static const List<String> revokedRoles = ['anon', 'public'];

  /// Params sent by the Flutter client — never a target user id.
  static Map<String, dynamic> rpcParams() => const {};

  /// `anon` / signed-out callers cannot invoke the RPC.
  static bool isCallable({
    required String role,
    required bool hasSession,
  }) {
    if (!hasSession) return false;
    if (revokedRoles.contains(role)) return false;
    return executeRoles.contains(role);
  }

  /// A caller may only delete themselves. There is no target-id argument, so a
  /// different [targetUserId] is never honored.
  static bool canDeleteUser({
    required String callerId,
    String? targetUserId,
  }) {
    if (callerId.isEmpty) return false;
    if (targetUserId != null && targetUserId != callerId) return false;
    return argumentNames.isEmpty;
  }
}

/// Result of the in-app confirm dialog. The RPC is called only when both
/// [isSignedIn] and [confirmed] are true.
class DeleteAccountConfirmation {
  const DeleteAccountConfirmation({
    required this.isSignedIn,
    required this.confirmed,
  });

  final bool isSignedIn;
  final bool confirmed;

  bool get shouldCallRpc => isSignedIn && confirmed;
}
