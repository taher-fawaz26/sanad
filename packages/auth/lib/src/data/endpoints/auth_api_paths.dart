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

  // ── Unified client sign-in (email OR UAE phone) ──────────────────────────
  //
  // One OTP flow for both first-time and returning clients; the server, not
  // the app, decides which. `{method, value}` keyed. Do NOT use the
  // provider `auth/login*` paths for clients.

  /// Client step 1 — dispatch a code. `{method, value}` in, no auth.
  static const String clientRequestOtp = 'auth/client/request-otp';

  /// Client resend cooldown — `GET`, query `method`+`value`, no auth.
  /// `ResendInfoResponseDto`.
  static const String clientResendInfo = 'auth/client/resend-info';

  /// Client step 2 — verify code, branch on `status`. `{method, value, otp}`
  /// in, no auth. `ClientVerifyResponseDto`.
  static const String clientVerify = 'auth/client/verify';

  /// Set client display name / preferred language. `PATCH`, bearer
  /// (client accounts only). Replaces client use of `account-settings`.
  static const String clientsMe = 'clients/me';
}
