import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  PreferencesService(this._preferences);

  final SharedPreferences _preferences;

  static const _currentUserIdKey = 'current_user_id';
  static const _welcomeShownKey = 'welcome_shown';

  String? get currentUserId => _preferences.getString(_currentUserIdKey);

  Future<void> saveCurrentUserId(String userId) {
    return _preferences.setString(_currentUserIdKey, userId);
  }

  Future<void> clearSession() async {
    await _preferences.remove(_currentUserIdKey);
  }

  bool hasShownWelcome(String userId) {
    return _preferences.getBool('$_welcomeShownKey:$userId') ?? false;
  }

  Future<void> markWelcomeShown(String userId) {
    return _preferences.setBool('$_welcomeShownKey:$userId', true);
  }
}
