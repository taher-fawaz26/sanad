/// Route paths owned by the account_settings feature.
abstract final class AccountSettingsRoutes {
  AccountSettingsRoutes._();

  /// Account settings hub — Figma settings menu → Account settings.
  static const String hub = '/settings/account';

  /// Delete-account entry point — eligibility → confirmation. OTP is presented
  /// as a bottom-sheet modal over this page (see `showDeletionOtpSheet`), not
  /// as a separate route.
  static const String deletion = '/settings/account/deletion';

  /// Scheduled-deletion status — shown after OTP verification and again on
  /// resuming an already-scheduled request.
  static const String deletionScheduled =
      '/settings/account/deletion/scheduled';

  /// Routes that require an authenticated session.
  static const Set<String> protectedRoutes = {
    hub,
    deletion,
    deletionScheduled,
  };
}
