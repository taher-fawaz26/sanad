/// Models `LoginResponseDto.status` — returned by `POST /auth/login/verify`
/// and `POST /auth/social/login`.
///
/// Deliberately separate from [AuthSessionStatus]: the two enums are not the
/// same wire concept. `AuthSessionStatus` (`onboarding | authenticated`)
/// discriminates the signup/profile `oneOf` response shape; this one
/// discriminates account state on the *login* path, including statuses
/// (`suspended`, `scheduledForDeletion`) that have no analogue there at all.
enum AuthAccountStatus {
  active('ACTIVE'),
  suspended('SUSPENDED'),
  incomplete('INCOMPLETE'),

  /// Sign-in during the account-deletion grace period auto-cancels the
  /// deletion and returns `ACTIVE` — this status is returned only for the
  /// real terminal lockout, once deletion has moved past the grace period
  /// into actual execution.
  scheduledForDeletion('SCHEDULED_FOR_DELETION')
  ;

  const AuthAccountStatus(this.value);

  final String value;

  static AuthAccountStatus fromString(String value) {
    final normalized = value.trim().toUpperCase();
    return AuthAccountStatus.values.firstWhere(
      (status) => status.value == normalized,
      orElse: () => throw FormatException(
        'Unknown LoginResponseDto.status: "$value".',
      ),
    );
  }
}
