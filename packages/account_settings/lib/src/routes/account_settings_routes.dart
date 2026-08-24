/// Route paths owned by the account_settings feature.
abstract final class AccountSettingsRoutes {
  AccountSettingsRoutes._();

  /// Account settings hub — Figma settings menu → Account settings.
  static const String hub = '/settings/account';

  /// Delete-account entry point — eligibility → confirmation.
  static const String deletion = '/settings/account/deletion';

  /// Delete-account OTP verification.
  static const String deletionOtp = '/settings/account/deletion/otp';

  /// Scheduled-deletion status — shown after OTP verification and again on
  /// resuming an already-scheduled request.
  static const String deletionScheduled =
      '/settings/account/deletion/scheduled';

  /// Routes that require an authenticated session.
  static const Set<String> protectedRoutes = {
    hub,
    deletion,
    deletionOtp,
    deletionScheduled,
  };
}
