import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/usecases/request_email_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/verify_email_otp_usecase.dart';
import 'package:otp/otp.dart';

/// Bridges the `otp` package's generic verification flow to the
/// organization's add/change-email use cases. Verification also commits the
/// new email address server-side — there is no separate "update email" call.
class OrganizationEmailOtpVerifier implements OtpVerifier<void> {
  const OrganizationEmailOtpVerifier({
    required String email,
    required RequestEmailOtpUseCase requestOtp,
    required VerifyEmailOtpUseCase verifyOtp,
  }) : _email = email,
       _requestOtp = requestOtp,
       _verifyOtp = verifyOtp;

  final String _email;
  final RequestEmailOtpUseCase _requestOtp;
  final VerifyEmailOtpUseCase _verifyOtp;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() {
    return _requestOtp
        .call(RequestEmailOtpParams(email: _email))
        .map((_) => const OtpDelivery());
  }

  @override
  TaskEither<Failure, void> verifyCode(String code) {
    return _verifyOtp
        .call(VerifyEmailOtpParams(email: _email, otp: code))
        .map((_) {});
  }
}
