import 'package:shared_preferences/shared_preferences.dart';

/// Device-local record of who finished role select.
///
/// `profiles.role` defaults to `consumer`, so the row itself cannot tell
/// "picked consumer" from "never picked". [AuthController] used to keep that
/// only in memory (`_roleChosenBy`); a process death before the name is saved
/// sent the user back to `/auth/role` and let them overwrite vendor→consumer.
class RoleChoiceStore {
  RoleChoiceStore(this._prefs);

  static const prefsKey = 'dahr_role_chosen_by';

  final SharedPreferences _prefs;

  static Future<RoleChoiceStore> open() async {
    return RoleChoiceStore(await SharedPreferences.getInstance());
  }

  String? get chosenBy => _prefs.getString(prefsKey);

  bool isChosenBy(String userId) => chosenBy == userId;

  Future<void> remember(String userId) => _prefs.setString(prefsKey, userId);

  Future<void> forget() => _prefs.remove(prefsKey);
}

/// In-memory pick or the persisted uid — either one counts after a restart.
bool isRoleChosenForUser({
  required String userId,
  required String? inMemoryChosenBy,
  required String? persistedChosenBy,
}) {
  return inMemoryChosenBy == userId || persistedChosenBy == userId;
}
