import 'package:auth/src/domain/entities/auth_response_entity.dart';
import 'package:auth/src/domain/entities/login_result_entity.dart';
import 'package:auth/src/domain/usecases/get_resend_info_usecase.dart';
import 'package:auth/src/domain/usecases/request_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/request_signup_otp_usecase.dart';
import 'package:auth/src/domain/usecases/resend_otp_usecase.dart';
import 'package:auth/src/domain/usecases/usecase_params.dart';
import 'package:auth/src/domain/usecases/verify_login_otp_usecase.dart';
import 'package:auth/src/domain/usecases/verify_signup_otp_usecase.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// Shared plumbing for the two email-OTP verifiers.
///
/// Both intents send, resend and read cooldown through exactly the same
/// endpoints keyed on the email address; only *verification* differs. That
/// difference is the whole reason there are two classes rather than one:
/// `signup/verify` resolves to an [AuthResponseEntity] and `login/verify` to
/// a [LoginResult], and no single generic verifier can be honest about both.
/// Splitting on the type parameter keeps each one exact.
abstract class _EmailOtpVerifier<T> implements OtpVerifier<T> {
  const _EmailOtpVerifier({
    required this.email,
    required ResendOtpUseCase resendOtp,
    required GetResendInfoUseCase getResendInfo,
  }) : _resendOtp = resendOtp,
       _getResendInfo = getResendInfo;

  final String email;
  final ResendOtpUseCase _resendOtp;
  final GetResendInfoUseCase _getResendInfo;

  RequestEmailOtpParams get _params => RequestEmailOtpParams(email: email);

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
}

/// Registration: `POST /auth/signup` then `POST /auth/signup/verify`.
///
/// Always resolves to an onboarding-shaped response — an account that is
/// already set up is rejected upstream with 409 — so the caller can route
/// straight into profile creation.
class SignupOtpVerifier extends _EmailOtpVerifier<AuthResponseEntity> {
  const SignupOtpVerifier({
    required super.email,
    required super.resendOtp,
    required super.getResendInfo,
    required RequestSignupOtpUseCase requestOtp,
    required VerifySignupOtpUseCase verifyOtp,
  }) : _requestOtp = requestOtp,
       _verifyOtp = verifyOtp;

  final RequestSignupOtpUseCase _requestOtp;
  final VerifySignupOtpUseCase _verifyOtp;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() =>
      _requestOtp(_params).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, AuthResponseEntity> verifyCode(String code) =>
      _verifyOtp(VerifyEmailOtpParams(email: email, otp: code));
}

/// Sign-in: `POST /auth/login` then `POST /auth/login/verify`.
///
/// Resolves to a [LoginResult] whose `status` the caller must branch on —
/// ACTIVE, INCOMPLETE, SUSPENDED and SCHEDULED_FOR_DELETION all arrive as a
/// *success*, not an error, so that decision stays with the page.
class LoginOtpVerifier extends _EmailOtpVerifier<LoginResult> {
  const LoginOtpVerifier({
    required super.email,
    required super.resendOtp,
    required super.getResendInfo,
    required RequestLoginOtpUseCase requestOtp,
    required VerifyLoginOtpUseCase verifyOtp,
  }) : _requestOtp = requestOtp,
       _verifyOtp = verifyOtp;

  final RequestLoginOtpUseCase _requestOtp;
  final VerifyLoginOtpUseCase _verifyOtp;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() =>
      _requestOtp(_params).map((_) => const OtpDelivery());

  @override
  TaskEither<Failure, LoginResult> verifyCode(String code) =>
      _verifyOtp(VerifyEmailOtpParams(email: email, otp: code));
}
