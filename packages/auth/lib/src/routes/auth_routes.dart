/// Named route path constants for the auth feature.
///
/// Each app's top-level GoRouter references these so route strings
/// stay in sync with the presentation layer.
abstract final class AuthRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
}
