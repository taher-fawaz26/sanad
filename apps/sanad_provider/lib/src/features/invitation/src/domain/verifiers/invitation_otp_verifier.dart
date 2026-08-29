import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/accept_invitation_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/get_invitation_resend_info_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/request_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/resend_invitation_otp_usecase.dart';
import 'package:sanad_provider/src/features/invitation/src/domain/usecases/usecase_params.dart';

/// Binds the worker-invitation acceptance endpoints to the shared OTP engine.
///
/// The invitation trio mirrors every other OTP family in the contract:
/// `request-otp` opens the session, `resend-otp` re-sends on it, and
/// `resend-info/{token}` reports the cooldown — so the engine's own
/// probe-then-send sequencing applies unchanged, and this page no longer has
/// to bootstrap the session by hand before opening the flow.
class InvitationOtpVerifier implements OtpVerifier<AuthSessionEntity> {
  const InvitationOtpVerifier({
    required this.token,
    required RequestInvitationOtpUseCase requestOtp,
    required ResendInvitationOtpUseCase resendOtp,
    required GetInvitationResendInfoUseCase getResendInfo,
    required AcceptInvitationUseCase acceptInvitation,
  }) : _requestOtp = requestOtp,
       _resendOtp = resendOtp,
       _getResendInfo = getResendInfo,
       _acceptInvitation = acceptInvitation;

  /// The unique invitation token from the emailed link.
  final String token;

  final RequestInvitationOtpUseCase _requestOtp;
  final ResendInvitationOtpUseCase _resendOtp;
  final GetInvitationResendInfoUseCase _getResendInfo;
  final AcceptInvitationUseCase _acceptInvitation;

  InvitationTokenParams get _params => InvitationTokenParams(token: token);

  @override
  TaskEither<Failure, OtpDelivery> requestCode() =>
      _requestOtp(_params).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, OtpDelivery> resendCode() =>
      _resendOtp(_params).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, OtpCooldown> cooldown() => _getResendInfo(_params).map(
    (info) => OtpCooldown(
      canResend: info.canResend,
      remainingSeconds: info.remainingSeconds,
      // `attemptsLeft` counts RESENDS, not wrong-code tries.
      resendsLeft: info.attemptsLeft,
    ),
  );

  @override
  TaskEither<Failure, AuthSessionEntity> verifyCode(String code) =>
      _acceptInvitation(AcceptInvitationParams(token: token, otp: code));
}
