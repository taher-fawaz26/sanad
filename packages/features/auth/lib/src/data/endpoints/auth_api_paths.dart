abstract final class AuthApiPaths {
  AuthApiPaths._();

  /// Step 1 signup — email a signup OTP.
  /// `EmailDto` in, `OtpDispatchResponseDto`.
  static const String signup = 'auth/signup';

  /// Step 2 signup — verify OTP, get an onboarding token.
  /// `EmailOtpDto` in, `OnboardingAuthResponseDto`.
  static const String signupVerify = 'auth/signup/verify';

  /// Step 1 sign-in — email a login OTP.
  /// `EmailDto` in, `OtpDispatchResponseDto`.
  static const String login = 'auth/login';

  /// Step 2 sign-in — verify OTP, branch on status.
  /// `EmailOtpDto` in, `LoginResponseDto`.
  static const String loginVerify = 'auth/login/verify';

  /// Register with Google/Apple → onboarding token.
  /// `SocialLoginDto` in, `OnboardingAuthResponseDto`.
  static const String socialSignup = 'auth/social/signup';

  /// Sign in with Google/Apple, branch on status.
  /// `SocialLoginDto` in, `LoginResponseDto`.
  static const String socialLogin = 'auth/social/login';

  /// Resend the active email OTP (single endpoint, not split by intent).
  static const String resendOtp = 'auth/resend-otp';

  /// OTP resend cooldown — `GET`, query `email`. `ResendInfoResponseDto`.
  static const String resendInfo = 'auth/resend-info';

  static const String logout = 'auth/logout';

  /// Canonical identity for every persona. `GET`, bearer. `MeResponseDto`.
  static const String me = 'me';

  /// Not documented under the `Auth` tag in the live OpenAPI spec — kept for
  /// now pending confirmation with the backend team (open question, plan
  /// §31 Q1). May 404 in production.
  static String userDelete(String userSub) => 'user/delete/$userSub';
}
