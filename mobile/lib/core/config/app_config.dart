/// Central application configuration.
/// Placeholder values — edit via Settings or supply actual values in setup.
class AppConfig {
  AppConfig._();

  static const String appName = 'App Paril';
  static const String appVersion = '1.0.0';
  static const String developerName = 'Sahan';

  // SharedPreferences keys
  static const String keySelectedRole = 'selected_role';
  static const String keyDeveloperMessage = 'developer_message';
  static const String keyRelationshipStartDate = 'relationship_start_date';
  static const String keySetupComplete = 'setup_complete';
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyFlappyHighScore = 'flappy_high_score';
  static const String keyFlappyIceCreamCount = 'flappy_ice_cream_count';
  static const String keyPlayerName = 'player_name';

  /// Developer message shown on the developer message screen.
  static const String defaultDeveloperMessage =
      'Thank you for believing in me Paril , even when I used to struggle in believing  myself. Your love, trust, and support has always given me strength when life gets hard.\n\n'
      ' I know I\'m not perfect, but I  want to grow into someone you\'re proud of. No matter what life brings, I always want you beside me through it all.\n\n'
      'Through every change and every chapter, my heart will always choose you. I\'ll celebrate your happiness, hold you through your sadness, and love every version of you.\n\n'
      'I can\'t promise life will always be easy, but I promise to keep choosing you and loving you with all my heart. Even in a thousand lifetimes, I\'d find you every time. Forever will never be long enough with you.\n\n'
      'I built this app just for you, Paril. I hope every time you open it, you feel how much you mean to me. ❤️';
}
