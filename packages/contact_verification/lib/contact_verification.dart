/// Shared contact-verification flow.
///
/// One `ContactVerificationRepository`, one `ContactVerificationVerifier`
/// (an `otp` package `OtpVerifier`), parameterized by `VerificationPurpose`.
/// Both `organization_settings` (business contact) and `account_settings`
/// (owner contact) depend on this instead of building their own OTP flow.
library;

export 'src/di/contact_verification_di.dart';
export 'src/domain/entities/verification_dispatch.dart';
export 'src/domain/entities/verification_purpose.dart';
export 'src/domain/entities/verification_resend_info.dart';
export 'src/domain/entities/verification_result.dart';
export 'src/domain/repositories/contact_verification_repository.dart';
export 'src/domain/usecases/contact_verification_params.dart';
export 'src/domain/usecases/get_resend_info_usecase.dart';
export 'src/domain/usecases/request_verification_usecase.dart';
export 'src/domain/usecases/resend_verification_usecase.dart';
export 'src/domain/usecases/verify_contact_usecase.dart';
export 'src/domain/verifiers/contact_verification_verifier.dart';
export 'src/module/contact_verification_module.dart';
export 'src/presentation/widgets/contact_change_sheet.dart';
