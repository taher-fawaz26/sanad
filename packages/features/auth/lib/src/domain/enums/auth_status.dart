enum AuthStatus {
  onboarding('onboarding'),
  authenticated('authenticated')
  ;

  const AuthStatus(this.value);

  final String value;

  static AuthStatus fromString(String value) {
    return AuthStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => throw ArgumentError('Unknown AuthStatus: $value'),
    );
  }
}
