abstract final class AuthApiPaths {
  AuthApiPaths._();

  /// Passwordless authentication — request an email OTP.
  static const String emailRequestOtp = 'auth/email/request-otp';

  /// Passwordless authentication — verify the email OTP.
  static const String emailVerify = 'auth/email/verify';

  static const String logout = 'auth/logout';

  /// Google OAuth — exchange a Firebase ID token for a SANAD session.
  static const String googleSignIn = 'auth/social';

  static String userDelete(String userSub) => 'user/delete/$userSub';
}
