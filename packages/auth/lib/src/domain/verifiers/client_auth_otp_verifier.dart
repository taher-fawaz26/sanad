import 'package:auth/src/domain/entities/client_verify_result_entity.dart';
import 'package:auth/src/domain/enums/client_auth_method.dart';
import 'package:auth/src/domain/usecases/get_client_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/request_client_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_client_otp_usecase.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// The unified client sign-in verifier that drives the shared OTP engine.
///
/// One verifier for both first-time and returning clients — the server
/// decides which, so there is no register/login split. It keys every step on
/// the exact `{method, value}` the code was requested for:
/// - [requestCode]/[resendCode] both hit `auth/client/request-otp` (there is
///   no separate resend endpoint);
/// - [cooldown] reads `auth/client/resend-info` and maps it to [OtpCooldown]
///   so the countdown reflects the server's `60s → 120s → 180s` ladder;
/// - [verifyCode] returns the raw [ClientVerifyResult] for the caller to
///   branch on (`status` + `user.name`).
///
/// Verification wrong/expired-code errors are surfaced inline by the engine
/// (`OtpBloc._verifyFailurePhase`); nothing status-specific is decided here.
class ClientAuthOtpVerifier implements OtpVerifier<ClientVerifyResult> {
  const ClientAuthOtpVerifier({
    required this.method,
    required this.value,
    required RequestClientOtpUseCase requestOtp,
    required VerifyClientOtpUseCase verifyOtp,
    required GetClientResendInfoUseCase getResendInfo,
  }) : _requestOtp = requestOtp,
       _verifyOtp = verifyOtp,
       _getResendInfo = getResendInfo;

  final ClientAuthMethod method;

  /// The exact identifier used for `request-otp`; reused verbatim for verify.
  final String value;

  final RequestClientOtpUseCase _requestOtp;
  final VerifyClientOtpUseCase _verifyOtp;
  final GetClientResendInfoUseCase _getResendInfo;

  ClientOtpParams get _params => ClientOtpParams(method: method, value: value);

  @override
  TaskEither<Failure, OtpDelivery> requestCode() =>
      _requestOtp(_params).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, OtpDelivery> resendCode() =>
      _requestOtp(_params).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, OtpCooldown> cooldown() => _getResendInfo(_params).map(
    (info) => OtpCooldown(
      canResend: info.canResend,
      remainingSeconds: info.remainingSeconds,
      // `attemptsLeft` counts remaining SENDS for the live code, not
      // wrong-code tries.
      resendsLeft: info.attemptsLeft,
    ),
  );

  @override
  TaskEither<Failure, ClientVerifyResult> verifyCode(String code) => _verifyOtp(
    VerifyClientOtpParams(method: method, value: value, otp: code),
  );
}
