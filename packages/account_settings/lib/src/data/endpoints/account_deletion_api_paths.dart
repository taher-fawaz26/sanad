/// Backend endpoints for the self-service account deletion & recovery flow.
abstract final class AccountDeletionApiPaths {
  AccountDeletionApiPaths._();

  /// `GET` — eligibility, blockers, warnings, live cascade preview.
  static const String eligibility = 'account/deletion/eligibility';

  /// `GET` — OTP resend cooldown and attempt availability.
  static const String resendInfo = 'account/deletion/resend-info';

  /// `POST` initiate (idempotent) / `GET` active request / `DELETE` in-app
  /// cancel (`@AllowSuspended`) — same path, three methods.
  static const String deletion = 'account/deletion';

  /// `POST` — verify OTP, schedules deletion (starts grace period).
  static const String verify = 'account/deletion/verify';

  /// `POST` — resend the verification OTP.
  static const String resendOtp = 'account/deletion/resend-otp';
}
