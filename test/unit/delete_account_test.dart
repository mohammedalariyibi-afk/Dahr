import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/features/auth/account_deletion.dart';

void main() {
  group('DeleteAccountRpcSpec', () {
    test('has no user-id argument so a client cannot target someone else', () {
      expect(DeleteAccountRpcSpec.rpcName, 'delete_own_account');
      expect(DeleteAccountRpcSpec.argumentNames, isEmpty);
      expect(DeleteAccountRpcSpec.rpcParams(), isEmpty);
      expect(DeleteAccountRpcSpec.rpcParams().containsKey('user_id'), isFalse);
      expect(DeleteAccountRpcSpec.rpcParams().containsKey('p_user_id'), isFalse);
      expect(DeleteAccountRpcSpec.securityDefiner, isTrue);
    });

    test('anon and signed-out callers cannot invoke the RPC', () {
      expect(
        DeleteAccountRpcSpec.isCallable(role: 'anon', hasSession: false),
        isFalse,
      );
      expect(
        DeleteAccountRpcSpec.isCallable(role: 'anon', hasSession: true),
        isFalse,
      );
      expect(
        DeleteAccountRpcSpec.isCallable(
          role: 'authenticated',
          hasSession: false,
        ),
        isFalse,
      );
      expect(
        DeleteAccountRpcSpec.isCallable(
          role: 'authenticated',
          hasSession: true,
        ),
        isTrue,
      );
      expect(DeleteAccountRpcSpec.executeRoles, ['authenticated']);
      expect(DeleteAccountRpcSpec.revokedRoles, containsAll(['anon', 'public']));
    });

    test('cannot delete another user id', () {
      expect(
        DeleteAccountRpcSpec.canDeleteUser(
          callerId: 'user-a',
          targetUserId: 'user-b',
        ),
        isFalse,
      );
      expect(
        DeleteAccountRpcSpec.canDeleteUser(callerId: 'user-a'),
        isTrue,
      );
      expect(
        DeleteAccountRpcSpec.canDeleteUser(
          callerId: 'user-a',
          targetUserId: 'user-a',
        ),
        isTrue,
      );
      expect(
        DeleteAccountRpcSpec.canDeleteUser(callerId: ''),
        isFalse,
      );
    });
  });

  group('DeleteAccountConfirmation', () {
    test('RPC runs only when signed-in user confirms the dialog', () {
      expect(
        const DeleteAccountConfirmation(isSignedIn: true, confirmed: true)
            .shouldCallRpc,
        isTrue,
      );
      expect(
        const DeleteAccountConfirmation(isSignedIn: true, confirmed: false)
            .shouldCallRpc,
        isFalse,
      );
      expect(
        const DeleteAccountConfirmation(isSignedIn: false, confirmed: true)
            .shouldCallRpc,
        isFalse,
      );
      expect(
        const DeleteAccountConfirmation(isSignedIn: false, confirmed: false)
            .shouldCallRpc,
        isFalse,
      );
    });
  });

  group('delete_own_account migration', () {
    late String sql;

    setUpAll(() {
      sql = File(
        'supabase/migrations/20260903140000_delete_own_account.sql',
      ).readAsStringSync();
    });

    test('SECURITY DEFINER deletes auth.uid() only and is not granted to anon', () {
      expect(sql, contains('SECURITY DEFINER'));
      expect(sql, contains('uid := auth.uid()'));
      expect(sql, contains('DELETE FROM auth.users WHERE id = uid'));
      expect(sql, isNot(contains('p_user_id')));
      expect(
        sql,
        contains('GRANT EXECUTE ON FUNCTION public.delete_own_account() TO authenticated'),
      );
      expect(
        sql,
        contains('REVOKE ALL ON FUNCTION public.delete_own_account() FROM anon'),
      );
      expect(
        sql,
        contains('REVOKE ALL ON FUNCTION public.delete_own_account() FROM PUBLIC'),
      );
      expect(
        sql,
        isNot(contains('GRANT EXECUTE ON FUNCTION public.delete_own_account() TO anon')),
      );
    });
  });
}
