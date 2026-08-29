import 'package:contact_verification/src/domain/entities/verification_purpose.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:contact_verification/src/domain/usecases/get_resend_info_usecase.dart';
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
///
/// Stateless by design. An earlier version tracked "have I sent yet?" in a
/// mutable field to choose between request and resend, and set it *before*
/// the lazy `TaskEither` ran — so a failed first send still flipped it, and
/// every retry thereafter hit `/resend` against a session that was never
/// created (400, forever). The engine now asks for exactly what it wants and
/// the cooldown probe tells it which that is.
class ContactVerificationVerifier implements OtpVerifier<VerificationResult> {
  const ContactVerificationVerifier({
    required this.purpose,
    required this.target,
    required RequestVerificationUseCase requestVerification,
    required ResendVerificationUseCase resendVerification,
    required VerifyContactUseCase verifyContact,
    required GetResendInfoUseCase getResendInfo,
  }) : _requestVerification = requestVerification,
       _resendVerification = resendVerification,
       _verifyContact = verifyContact,
       _getResendInfo = getResendInfo;

  final VerificationPurpose purpose;
  final String target;

  final RequestVerificationUseCase _requestVerification;
  final ResendVerificationUseCase _resendVerification;
  final VerifyContactUseCase _verifyContact;
  final GetResendInfoUseCase _getResendInfo;

  @override
  TaskEither<Failure, OtpDelivery> requestCode() => _requestVerification(
    RequestVerificationParams(purpose: purpose, target: target),
  ).map((_) => OtpDelivery(maskedDestination: target));

  /// Resends on the live session, falling back to opening a new one.
  ///
  /// `/resend` answers 400 when no session exists — which is recoverable, not
  /// fatal: `/request` opens one. Without this the user is stuck behind an
  /// error with no way forward but to close the sheet.
  @override
  TaskEither<Failure, OtpDelivery> resendCode() =>
      _resendVerification(ResendVerificationParams(purpose: purpose))
          .map((_) => OtpDelivery(maskedDestination: target))
          .orElse(
            (failure) => failure is ValidationFailure
                ? requestCode()
                : TaskEither.left(failure),
          );

  @override
  TaskEither<Failure, OtpCooldown> cooldown() =>
      _getResendInfo(ResendInfoParams(purpose: purpose)).map(
        (info) => OtpCooldown(
          canResend: info.canResend,
          remainingSeconds: info.remainingSeconds,
          // The backend's `attemptsLeft` counts RESENDS, not wrong-code tries.
          resendsLeft: info.attemptsLeft,
        ),
      );

  @override
  TaskEither<Failure, VerificationResult> verifyCode(String code) =>
      _verifyContact(VerifyContactParams(purpose: purpose, code: code));
}
