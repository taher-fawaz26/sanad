abstract final class AuthApiPaths {
  AuthApiPaths._();

  static const String login = 'auth/login';
  static const String register = 'auth/register';
  static const String validateOtp = 'auth/validate-otp';
  static const String forgotPassword = 'auth/forgot-password';
  static const String resetPassword = 'auth/reset-password';
  static const String resendOtp = 'otp/resend';

  static String userDelete(String userSub) => 'user/delete$userSub';
}
