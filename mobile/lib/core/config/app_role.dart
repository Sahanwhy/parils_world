/// User roles for the app.
/// NOTE: This is a UX convenience, not strong authentication.
/// Private data must still be gated separately (future PIN/biometric).
enum AppRole {
  paril('Paril'),
  friends('Friends'),
  family('Family');

  const AppRole(this.displayName);
  final String displayName;

  /// True when the role should have access to private/romantic content.
  bool get isPrivate => this == AppRole.paril;

  static AppRole fromString(String value) {
    return AppRole.values.firstWhere(
      (r) => r.name == value,
      orElse: () => AppRole.paril,
    );
  }
}
