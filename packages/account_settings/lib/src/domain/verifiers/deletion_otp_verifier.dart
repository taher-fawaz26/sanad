import 'package:account_settings/src/domain/entities/account_deletion_request.dart';
import 'package:account_settings/src/domain/usecases/get_deletion_resend_info_usecase.dart';
import 'package:account_settings/src/domain/usecases/resend_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/verify_deletion_otp_usecase.dart';
import 'package:account_settings/src/domain/usecases/account_settings_params.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// Binds account-deletion confirmation to the shared OTP engine.
///
/// The deletion request is created — and its first code sent — by
/// `POST /account/deletion` before this flow opens, so the config runs with
/// `autoSendOnStart: false` and the engine goes straight to reading the
/// server cooldown.
///
/// Verification carries side effects that must not be separable from it: once
/// deletion is scheduled the session has to end, exactly as a logout would.
/// Keeping them here (rather than in a bloc handler the UI could bypass)
/// means no caller can verify without also ending the session.
class DeletionOtpVerifier implements OtpVerifier<AccountDeletionRequest> {
  const DeletionOtpVerifier({
    required VerifyDeletionOtpUseCase verifyOtp,
    required ResendDeletionOtpUseCase resendOtp,
    required GetDeletionResendInfoUseCase getResendInfo,
    required AuthLogoutUseCase logout,
    required SessionManager sessionManager,
  }) : _verifyOtp = verifyOtp,
       _resendOtp = resendOtp,
       _getResendInfo = getResendInfo,
       _logout = logout,
       _sessionManager = sessionManager;

  final VerifyDeletionOtpUseCase _verifyOtp;
  final ResendDeletionOtpUseCase _resendOtp;
  final GetDeletionResendInfoUseCase _getResendInfo;
  final AuthLogoutUseCase _logout;
  final SessionManager _sessionManager;

  /// The initiating request already sent a code; re-issuing one is a resend.
  @override
  TaskEither<Failure, OtpDelivery> requestCode() => resendCode();

  @override
  TaskEither<Failure, OtpDelivery> resendCode() =>
      _resendOtp(const NoParams()).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, OtpCooldown> cooldown() =>
      _getResendInfo(const NoParams()).map(
        (info) => OtpCooldown(
          canResend: info.canResend,
          remainingSeconds: info.remainingSeconds,
          // `attemptsLeft` counts RESENDS, not wrong-code tries.
          resendsLeft: info.attemptsLeft,
        ),
      );

  @override
  TaskEither<Failure, AccountDeletionRequest> verifyCode(String code) =>
      _verifyOtp(VerifyDeletionOtpParams(otp: code)).flatMap(
        (request) => TaskEither<Failure, AccountDeletionRequest>.fromTask(
          Task(() async {
            // Best-effort server logout; the local session is wiped
            // unconditionally so the user is never left signed into an
            // account that is scheduled for deletion.
            await _logout(const NoParams()).run();
            await _sessionManager.clear();
            return request;
          }),
        ),
      );
}
