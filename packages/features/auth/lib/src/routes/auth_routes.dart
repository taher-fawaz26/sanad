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
}
