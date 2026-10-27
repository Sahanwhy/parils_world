import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../config/app_role.dart';

/// Local key-value storage wrapper using SharedPreferences.
/// All persistence for Milestone 1 goes through this service.
class LocalStorageService {
  LocalStorageService._();

  static LocalStorageService? _instance;
  static SharedPreferences? _prefs;

  static Future<LocalStorageService> getInstance() async {
    _instance ??= LocalStorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  SharedPreferences get _p {
    assert(_prefs != null, 'LocalStorageService not initialised');
    return _prefs!;
  }

  // ── Role ───────────────────────────────────────────────────────────────────
  AppRole getRole() {
    final stored = _p.getString(AppConfig.keySelectedRole);
    if (stored == null) return AppRole.paril;
    return AppRole.fromString(stored);
  }

  Future<void> setRole(AppRole role) =>
      _p.setString(AppConfig.keySelectedRole, role.name);

  // ── Developer message ──────────────────────────────────────────────────────
  String getDeveloperMessage() {
    final stored = _p.getString(AppConfig.keyDeveloperMessage);
    if (stored == null ||
        stored.startsWith('Hey Paril') ||
        !stored.contains('Even in a thousand lifetimes, I\'d find you every time')) {
      return AppConfig.defaultDeveloperMessage;
    }
    return stored;
  }

  Future<void> setDeveloperMessage(String message) =>
      _p.setString(AppConfig.keyDeveloperMessage, message);

  // ── Relationship date ──────────────────────────────────────────────────────
  String? getRelationshipStartDate() =>
      _p.getString(AppConfig.keyRelationshipStartDate);

  Future<void> setRelationshipStartDate(String isoDate) =>
      _p.setString(AppConfig.keyRelationshipStartDate, isoDate);

  Future<void> clearRelationshipStartDate() =>
      _p.remove(AppConfig.keyRelationshipStartDate);

  // ── Setup / onboarding ────────────────────────────────────────────────────
  bool isSetupComplete() => _p.getBool(AppConfig.keySetupComplete) ?? false;

  Future<void> setSetupComplete({required bool complete}) =>
      _p.setBool(AppConfig.keySetupComplete, complete);

  bool isOnboardingComplete() =>
      _p.getBool(AppConfig.keyOnboardingComplete) ?? false;

  Future<void> setOnboardingComplete({required bool complete}) =>
      _p.setBool(AppConfig.keyOnboardingComplete, complete);

  // ── Flappy Bird ───────────────────────────────────────────────────────────
  int getFlappyHighScore() => _p.getInt(AppConfig.keyFlappyHighScore) ?? 0;

  Future<void> setFlappyHighScore(int score) =>
      _p.setInt(AppConfig.keyFlappyHighScore, score);

  int getFlappyIceCreamCount() =>
      _p.getInt(AppConfig.keyFlappyIceCreamCount) ?? 0;

  Future<void> setFlappyIceCreamCount(int count) =>
      _p.setInt(AppConfig.keyFlappyIceCreamCount, count);

  // ── Player Name ───────────────────────────────────────────────────────────
  String? getPlayerName() => _p.getString(AppConfig.keyPlayerName);

  Future<void> setPlayerName(String name) =>
      _p.setString(AppConfig.keyPlayerName, name);
}

