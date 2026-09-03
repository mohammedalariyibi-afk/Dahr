import 'package:flutter_test/flutter_test.dart';
import 'package:dahr/core/models/enums.dart';
import 'package:dahr/core/models/profile.dart';
import 'package:dahr/core/providers/auth_provider.dart';
import 'package:dahr/core/routing/auth_redirect.dart';

Profile _profile({
  String? fullName,
  CityCode? city,
  UserRole role = UserRole.consumer,
}) {
  return Profile(
    id: 'u1',
    fullName: fullName,
    role: role,
    city: city,
  );
}

void main() {
  group('resolveAuthFlowStatus', () {
    test('a fresh row with no name and no role pick asks for the role', () {
      expect(
        resolveAuthFlowStatus(profile: _profile(), roleChosen: false),
        AuthFlowStatus.needsRole,
      );
      expect(
        resolveAuthFlowStatus(profile: null, roleChosen: false),
        AuthFlowStatus.needsRole,
      );
    });

    test('picking a role moves on to profile setup instead of asking again',
        () {
      expect(
        resolveAuthFlowStatus(
          profile: _profile(role: UserRole.vendor),
          roleChosen: true,
        ),
        AuthFlowStatus.needsProfile,
      );
      // A couple keeps the default role, so only the pick itself can tell us.
      expect(
        resolveAuthFlowStatus(profile: _profile(), roleChosen: true),
        AuthFlowStatus.needsProfile,
      );
    });

    test('a returning user with a name is never sent back to the role screen',
        () {
      expect(
        resolveAuthFlowStatus(
          profile: _profile(fullName: 'Salma'),
          roleChosen: false,
        ),
        AuthFlowStatus.needsProfile,
      );
      expect(
        resolveAuthFlowStatus(
          profile: _profile(fullName: 'Salma', city: CityCode.tripoli),
          roleChosen: false,
        ),
        AuthFlowStatus.authenticated,
      );
    });

    test('a blank name does not count as a finished profile', () {
      expect(
        resolveAuthFlowStatus(
          profile: _profile(fullName: '   ', city: CityCode.benghazi),
          roleChosen: true,
        ),
        AuthFlowStatus.needsProfile,
      );
    });
  });

  group('role pick then profile setup', () {
    test('the router lets a user who just picked a role reach profile setup',
        () {
      final status = resolveAuthFlowStatus(
        profile: _profile(role: UserRole.vendor),
        roleChosen: true,
      );
      expect(
        resolveAuthRedirect(
          location: '/auth/profile-setup',
          status: status,
          uri: Uri.parse('/auth/profile-setup'),
        ),
        isNull,
      );
    });

    test('without the pick the same user is held on the role screen', () {
      final status = resolveAuthFlowStatus(
        profile: _profile(role: UserRole.vendor),
        roleChosen: false,
      );
      expect(
        resolveAuthRedirect(
          location: '/auth/profile-setup',
          status: status,
          uri: Uri.parse('/auth/profile-setup'),
        ),
        '/auth/role',
      );
    });
  });
}
