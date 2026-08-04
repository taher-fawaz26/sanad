import 'package:auth/src/auth/auth_status.dart';
import 'package:auth/src/auth/auth_status_notifier.dart';
import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:network/network.dart';
import 'package:otp/otp.dart';

/// Bridges the `otp` package's generic verification flow to auth's
/// passwordless email login/signup.
///
/// The one and only OTP UI in the app lives in the `otp` package; this class
/// is the adapter that lets it drive auth's use cases. It also owns the
/// post-verify side effects ([SessionManager.startSession],
/// [AuthStatusNotifier.update]) that used to live in `AuthBloc._verifyOtp` —
/// there is no longer a second OTP state machine duplicating this flow.
class AuthOtpVerifier implements OtpVerifier<AuthResponseEntity> {
  const AuthOtpVerifier({
    required String email,
    required RequestEmailOtpUseCase requestEmailOtp,
    required VerifyEmailOtpUseCase verifyEmailOtp,
    required SessionManager sessionManager,
    required AuthStatusNotifier authStatusNotifier,
  }) : _email = email,
       _requestEmailOtp = requestEmailOtp,
       _verifyEmailOtp = verifyEmailOtp,
       _sessionManager = sessionManager,
       _authStatusNotifier = authStatusNotifier;

  final String _email;
  final RequestEmailOtpUseCase _requestEmailOtp;
  final VerifyEmailOtpUseCase _verifyEmailOtp;
  final SessionManager _sessionManager;
  final AuthStatusNotifier _authStatusNotifier;

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
              case AuthSessionEntity(
                :final accessToken,
                :final refreshToken,
                :final isProfileCreated,
              ):
                await _sessionManager.startSession(
                  accessToken: accessToken,
                  refreshToken: refreshToken,
                );
                _authStatusNotifier.update(
                  AuthStatus.authenticated,
                  isProfileCompleted: isProfileCreated,
                );
              case OnboardingAuthEntity():
                break;
            }
          }, (error, stack) => UnknownFailure(message: error.toString())),
        );
  }
}
