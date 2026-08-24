/// Named route path constants for the auth feature.
///
/// Each app's top-level GoRouter references these so route strings
/// stay in sync with the presentation layer.
abstract final class AuthRoutes {
  static const splash = '/';
  static const login = '/login';

  /// Shared passwordless OTP screen (Sign In + Sign Up). Expects the email
  /// address as the route `extra`.
  static const otp = '/otp';

  /// Shown when `login/verify` (or `social/login`) reports
  /// `status: SUSPENDED` — the account exists but has no usable session.
  static const suspended = '/suspended';

  /// Shown when `login/verify` (or `social/login`) reports
  /// `status: SCHEDULED_FOR_DELETION` — deletion has moved past the grace
  /// period into actual execution; the account is locked and has no usable
  /// session. (Sign-in during the grace period auto-cancels deletion and
  /// returns `ACTIVE` instead — this route is only reached for the real
  /// terminal case.)
  static const scheduledForDeletion = '/account-scheduled-for-deletion';
}
