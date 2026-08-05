import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/usecases/request_phone_otp_usecase.dart';
import 'package:organization_settings/src/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:otp/otp.dart';

/// Bridges the `otp` package's generic verification flow to the
/// organization's add/change-phone use cases. Verification also commits the
/// new phone number server-side — there is no separate "update phone" call.
class OrganizationPhoneOtpVerifier implements OtpVerifier<void> {
  const OrganizationPhoneOtpVerifier({
    required String phone,
    required RequestPhoneOtpUseCase requestOtp,
    required VerifyPhoneOtpUseCase verifyOtp,
  }) : _phone = phone,
       _requestOtp = requestOtp,
       _verifyOtp = verifyOtp;

  final String _phone;
  final RequestPhoneOtpUseCase _requestOtp;
  final VerifyPhoneOtpUseCase _verifyOtp;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() {
    return _requestOtp
        .call(RequestPhoneOtpParams(phone: _phone))
        .map((_) => const OtpDelivery());
  }

  @override
  TaskEither<Failure, void> verifyCode(String code) {
    return _verifyOtp
        .call(VerifyPhoneOtpParams(phone: _phone, otp: code))
        .map((_) {});
  }
}
