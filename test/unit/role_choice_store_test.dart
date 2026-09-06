import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/profile.dart';
import 'package:dahr/core/providers/auth_provider.dart';
import 'package:dahr/core/providers/role_choice_store.dart';
import 'package:dahr/core/routing/auth_redirect.dart';

Profile _profile({
  String id = 'u1',
  String? fullName,
  UserRole role = UserRole.consumer,
}) {
  return Profile(
    id: id,
    fullName: fullName,
    role: role,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('RoleChoiceStore', () {
    test('remembers the uid and survives a new store instance', () async {
      final first = RoleChoiceStore(await SharedPreferences.getInstance());
      expect(first.chosenBy, isNull);
      expect(first.isChosenBy('u1'), isFalse);

      await first.remember('u1');
      expect(first.isChosenBy('u1'), isTrue);
      expect(first.isChosenBy('u2'), isFalse);

      // Process death: a new store reads the same prefs.
      final restarted = RoleChoiceStore(await SharedPreferences.getInstance());
      expect(restarted.chosenBy, 'u1');
      expect(restarted.isChosenBy('u1'), isTrue);
    });

    test('forget clears the pick', () async {
      final store = RoleChoiceStore(await SharedPreferences.getInstance());
      await store.remember('u1');
      await store.forget();
      expect(store.chosenBy, isNull);
      expect(store.isChosenBy('u1'), isFalse);
    });
  });

  group('isRoleChosenForUser after a restart', () {
    test('persisted uid counts when in-memory flag is gone', () {
      expect(
        isRoleChosenForUser(
          userId: 'u1',
          inMemoryChosenBy: null,
          persistedChosenBy: 'u1',
        ),
        isTrue,
      );
      expect(
        isRoleChosenForUser(
          userId: 'u1',
          inMemoryChosenBy: null,
          persistedChosenBy: 'someone-else',
        ),
        isFalse,
      );
      expect(
        isRoleChosenForUser(
          userId: 'u1',
          inMemoryChosenBy: 'u1',
          persistedChosenBy: null,
        ),
        isTrue,
      );
    });
  });

  group('role pick survives process death', () {
    test('vendor pick is not sent back to /auth/role after a restart', () async {
      final store = RoleChoiceStore(await SharedPreferences.getInstance());
      await store.remember('u1');

      // Kill app: in-memory _roleChosenBy is gone; prefs still have the uid.
      final roleChosen = isRoleChosenForUser(
        userId: 'u1',
        inMemoryChosenBy: null,
        persistedChosenBy: store.chosenBy,
      );
      final status = resolveAuthFlowStatus(
        profile: _profile(role: UserRole.vendor),
        roleChosen: roleChosen,
      );
      expect(status, AuthFlowStatus.needsProfile);
      expect(
        resolveAuthRedirect(
          location: '/auth/role',
          status: status,
          uri: Uri.parse('/auth/role'),
        ),
        '/auth/profile-setup',
      );
    });

    test('without persist a nameless vendor can still overwrite at /auth/role',
        () {
      final status = resolveAuthFlowStatus(
        profile: _profile(role: UserRole.vendor),
        roleChosen: isRoleChosenForUser(
          userId: 'u1',
          inMemoryChosenBy: null,
          persistedChosenBy: null,
        ),
      );
      expect(status, AuthFlowStatus.needsRole);
      expect(
        resolveAuthRedirect(
          location: '/auth/role',
          status: status,
          uri: Uri.parse('/auth/role'),
        ),
        isNull,
      );
    });
  });
}
