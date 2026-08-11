/// Discriminator for the Swagger `oneOf` auth response payload.
///
/// Both `OnboardingAuthResponseDto` and `AuthSessionResponseDto` carry this
/// same two-value `status` field on the wire — `AuthResponseModel.fromJson`
/// switches on it to decide which DTO to parse.
///
/// Deliberately NOT named `AuthStatus`: that name is already used by the
/// presentation-layer `AuthStatusNotifier` status (`unknown` /
/// `authenticated` / `unauthenticated`), which tracks app-wide session state
/// rather than a single response's discriminator. Reusing the name would
/// force every file that needs both into an aliased import.
enum AuthSessionStatus {
  onboarding('onboarding'),
  authenticated('authenticated')
  ;

  const AuthSessionStatus(this.value);

  final String value;

  static AuthSessionStatus fromString(String value) {
    return AuthSessionStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () =>
          throw FormatException('Unknown auth response status: "$value".'),
    );
  }
}
