import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:auth/src/session/session_manager.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// Bridges the `otp` package's generic verification flow to auth's
/// passwordless email login/signup.
///
/// The one and only OTP UI in the app lives in the `otp` package; this class
/// is the adapter that lets it drive auth's use cases. On a successful
/// authenticated verify it hands the full [AuthSessionEntity] to
/// [SessionManager.save] — a single call that persists tokens, session
/// snapshot, and flips `AuthStatusNotifier` to authenticated.
class AuthOtpVerifier implements OtpVerifier<AuthResponseEntity> {
  const AuthOtpVerifier({
    required String email,
    required RequestEmailOtpUseCase requestEmailOtp,
    required VerifyEmailOtpUseCase verifyEmailOtp,
    required SessionManager sessionManager,
  }) : _email = email,
       _requestEmailOtp = requestEmailOtp,
       _verifyEmailOtp = verifyEmailOtp,
       _sessionManager = sessionManager;

  final String _email;
  final RequestEmailOtpUseCase _requestEmailOtp;
  final VerifyEmailOtpUseCase _verifyEmailOtp;
  final SessionManager _sessionManager;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() {
    return _requestEmailOtp
        .call(RequestEmailOtpParams(email: _email))
        .map((_) => const OtpDelivery());
  }

  @override
  TaskEither<Failure, AuthResponseEntity> verifyCode(String code) {
    return _verifyEmailOtp
        .call(VerifyEmailOtpParams(email: _email, otp: code))
        .chainFirst(
          (response) => TaskEither.tryCatch(() async {
            switch (response) {
              case final AuthSessionEntity session:
                await _sessionManager.save(session);
              case OnboardingAuthEntity():
                break;
            }
          }, (error, stack) => UnknownFailure(message: error.toString())),
        );
  }
}
