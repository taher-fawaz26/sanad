import 'package:core/core.dart';
import 'package:fpdart/fpdart.dart';
import 'package:organization_settings/src/domain/entities/organization_contact_entity.dart';

/// Reads and updates the organization's contact phone/email. Owned by the
/// feature — OTP verification itself is delegated to the transport-agnostic
/// `otp` package via `OrganizationPhoneOtpVerifier`/`OrganizationEmailOtpVerifier`.
abstract interface class OrganizationContactRepository {
  TaskEither<Failure, OrganizationContactEntity> getContact();

  TaskEither<Failure, Unit> requestPhoneOtp({required String phone});

  TaskEither<Failure, Unit> verifyPhoneOtp({
    required String phone,
    required String otp,
  });

  TaskEither<Failure, Unit> requestEmailOtp({required String email});

  TaskEither<Failure, Unit> verifyEmailOtp({
    required String email,
    required String otp,
  });
}
