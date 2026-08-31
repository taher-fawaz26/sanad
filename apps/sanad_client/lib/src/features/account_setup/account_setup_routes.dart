/// Route path constants for the post-authentication setup flow (Enter Name,
/// Get Notified), reached after OTP for both the Email and Phone flows.
///
/// Deliberately not under `/oauth/*` — these screens are not part of
/// authentication-method selection/entry, only reachable after it completes.
abstract final class AccountSetupRoutes {
  AccountSetupRoutes._();

  /// "What should I call you?"
  static const enterName = '/account-setup/name';

  /// "Get Notified".
  static const getNotified = '/account-setup/notifications';
}
