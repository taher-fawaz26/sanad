import 'package:contact_verification/src/domain/entities/verification_dispatch.dart';
import 'package:contact_verification/src/domain/entities/verification_resend_info.dart';
import 'package:contact_verification/src/domain/entities/verification_result.dart';
import 'package:contact_verification/src/domain/usecases/contact_verification_params.dart';
import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';

/// The unified `/contact-verification/*` contract.
///
/// Pure — no `SessionManager`, no UI. Callers (organization_settings for
/// business contact, account_settings for owner contact) decide what to do
/// with a successful [VerificationResult] (refresh a bloc, sync the session).
abstract interface class ContactVerificationRepository {
  TaskEither<Failure, VerificationDispatch> requestCode(
    RequestVerificationParams params,
  );

  TaskEither<Failure, VerificationDispatch> resendCode(
    ResendVerificationParams params,
  );

  TaskEither<Failure, VerificationResendInfo> getResendInfo(
    ResendInfoParams params,
  );

  TaskEither<Failure, VerificationResult> verifyCode(
    VerifyContactParams params,
  );
}
