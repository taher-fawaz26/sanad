import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:contact_verification/src/domain/usecases/request_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/resend_verification_usecase.dart';
import 'package:contact_verification/src/domain/usecases/verify_contact_usecase.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:otp/otp.dart';

/// The single `OtpVerifier` implementation for every contact-verification
/// flow — business or owner, email or phone. Callers (organization_settings,
/// account_settings) construct one per `(purpose, target)` and hand it to
/// `OtpFlow.start`; there is exactly one OTP integration in the app.
class ContactVerificationVerifier implements OtpVerifier<VerificationResult> {
  ContactVerificationVerifier({
    required this.purpose,
    required this.target,
    required RequestVerificationUseCase requestVerification,
    required ResendVerificationUseCase resendVerification,
    required VerifyContactUseCase verifyContact,
  }) : _requestVerification = requestVerification,
       _resendVerification = resendVerification,
       _verifyContact = verifyContact;

  final VerificationPurpose purpose;
  final String target;

  final RequestVerificationUseCase _requestVerification;
  final ResendVerificationUseCase _resendVerification;
  final VerifyContactUseCase _verifyContact;

  /// `true` once the first `requestCode()` call has been made — a resend
  /// after that reuses the resend endpoint (matches the backend's
  /// request-once / resend-after model).
  bool _requested = false;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() {
    final task = _requested
        ? _resendVerification(ResendVerificationParams(purpose: purpose))
        : _requestVerification(
            RequestVerificationParams(purpose: purpose, target: target),
          );
    _requested = true;
    return task.map(
      (dispatch) => OtpDelivery(maskedDestination: target),
    );
  }

  @override
  TaskEither<Failure, VerificationResult> verifyCode(String code) =>
      _verifyContact(VerifyContactParams(purpose: purpose, code: code));
}
