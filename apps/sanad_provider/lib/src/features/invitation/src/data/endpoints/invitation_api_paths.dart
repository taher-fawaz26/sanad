abstract final class InvitationApiPaths {
  InvitationApiPaths._();

  /// `GET /workers/verify-token/{token}` — path param, uuid. No bearer.
  /// `VerifyInvitationTokenResponseDto`. 400 if [token] isn't a valid uuid;
  /// no 404 — an unknown token still resolves 200 with `valid: false`.
  static String verifyToken(String token) => 'workers/verify-token/$token';

  /// `POST /workers/invitations/request-otp` — `RequestInvitationOtpDto` in,
  /// `OtpDispatchResponseDto`. 403 if the token is invalid/expired.
  static const String requestOtp = 'workers/invitations/request-otp';

  /// `POST /workers/invitations/resend-otp` — same shapes as [requestOtp].
  /// 400 if there's no active OTP session yet, 403 invalid/expired token,
  /// 429 cooldown/max resends.
  static const String resendOtp = 'workers/invitations/resend-otp';

  /// `GET /workers/invitations/resend-info/{token}` —
  /// `ResendInfoResponseDto`. 403 if the token is invalid/expired.
  static String resendInfo(String token) =>
      'workers/invitations/resend-info/$token';

  /// `POST /workers/invitations/accept` — `AcceptInvitationDto` in,
  /// `AuthSessionResponseDto` (the same shape as `auth/profile`). 400 invalid
  /// /expired OTP, 403 invalid/expired invitation token.
  static const String accept = 'workers/invitations/accept';
}
