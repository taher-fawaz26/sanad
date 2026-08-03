import 'package:asset_picker/asset_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:registration/src/data/models/extraction_result.dart';
import 'package:registration/src/domain/failures/registration_failure.dart';
import 'package:registration/src/domain/provider_type/provider_type_spec.dart';

/// Single async-operation state machine for the sign-up flow.
///
/// Replaces the former `ExtractionStatus` + `ProfileCompletionStatus` pair,
/// which could represent impossible combinations (both failed simultaneously).
/// Exactly one phase is active at any moment.
sealed class RegistrationAsyncPhase extends Equatable {
  const RegistrationAsyncPhase();

  @override
  List<Object?> get props => [];
}

/// No async operation is active — waiting for user input or navigation.
final class PhaseIdle extends RegistrationAsyncPhase {
  const PhaseIdle();
}

/// AI document extraction is running.
final class PhaseExtracting extends RegistrationAsyncPhase {
  const PhaseExtracting();
}

/// Extraction completed — results available in [RegistrationState.extraction].
final class PhaseExtractionDone extends RegistrationAsyncPhase {
  const PhaseExtractionDone();
}

/// Extraction failed — see [RegistrationState.failure] for the reason.
final class PhaseExtractionFailed extends RegistrationAsyncPhase {
  const PhaseExtractionFailed();
}

/// Profile completion API call is in progress.
final class PhaseSubmitting extends RegistrationAsyncPhase {
  const PhaseSubmitting();
}

/// Profile completion succeeded — registration is complete.
final class PhaseSubmissionDone extends RegistrationAsyncPhase {
  const PhaseSubmissionDone();
}

/// Profile completion failed — see [RegistrationState.failure].
final class PhaseSubmissionFailed extends RegistrationAsyncPhase {
  const PhaseSubmissionFailed();
}

/// Immutable state carried across the whole sign-up flow by the cubit.
///
/// A single instance lives for the duration of the `/signup` shell, so every
/// step reads and contributes to the same object.
///
/// Document slots use [UploadableAsset] exclusively — local file + upload
/// lifecycle + backend `remoteId` / `remoteUrl` after a successful upload.
class RegistrationState extends Equatable {
  const RegistrationState({
    this.email = '',
    this.onboardingToken,
    this.providerType,
    this.businessName = '',
    this.representativeName = '',
    this.fullName = '',
    this.emiratesIdFront,
    this.emiratesIdBack,
    this.tradeLicence,
    this.phase = const PhaseIdle(),
    this.extraction,
    this.failure,
  });

  final String email;

  /// Short-lived token issued by `auth/email/verify` for a new user; used to
  /// authorize the profile-creation calls that complete onboarding.
  final String? onboardingToken;

  /// The selected provider type, which determines the UI flow and submit
  /// endpoint. Null until the user has selected an account type.
  final ProviderTypeSpec? providerType;

  // Organization-path fields.
  final String businessName;
  final String representativeName;

  // Individual-path fields.
  final String fullName;

  // Captured documents (upload pipeline state).
  final UploadableAsset? emiratesIdFront;
  final UploadableAsset? emiratesIdBack;
  final UploadableAsset? tradeLicence;

  /// Current async phase of the sign-up flow.
  final RegistrationAsyncPhase phase;

  final ExtractionResult? extraction;

  /// Current typed failure, cleared once the UI has consumed it.
  final RegistrationFailure? failure;

  /// Whether the selected provider type follows the organisation flow
  /// (org-details form + trade-licence step).
  bool get isOrganization => providerType?.requiresTradeLicence ?? false;

  /// True once both Emirates ID sides have been uploaded successfully.
  bool get hasBothIdSides =>
      (emiratesIdFront?.isUploaded ?? false) &&
      (emiratesIdBack?.isUploaded ?? false);

  /// True once both Emirates ID sides have been captured locally
  /// (not uploaded).
  bool get hasBothIdSidesCaptured =>
      emiratesIdFront?.asset != null && emiratesIdBack?.asset != null;

  /// True once the trade licence has been uploaded successfully.
  bool get hasTradeLicenceUploaded => tradeLicence?.isUploaded ?? false;

  RegistrationState copyWith({
    String? email,
    String? onboardingToken,
    Object? providerType = _sentinel,
    String? businessName,
    String? representativeName,
    String? fullName,
    Object? emiratesIdFront = _sentinel,
    Object? emiratesIdBack = _sentinel,
    Object? tradeLicence = _sentinel,
    RegistrationAsyncPhase? phase,
    ExtractionResult? extraction,
    Object? failure = _sentinel,
  }) =>
      RegistrationState(
        email: email ?? this.email,
        onboardingToken: onboardingToken ?? this.onboardingToken,
        providerType: identical(providerType, _sentinel)
            ? this.providerType
            : providerType as ProviderTypeSpec?,
        businessName: businessName ?? this.businessName,
        representativeName: representativeName ?? this.representativeName,
        fullName: fullName ?? this.fullName,
        emiratesIdFront: identical(emiratesIdFront, _sentinel)
            ? this.emiratesIdFront
            : emiratesIdFront as UploadableAsset?,
        emiratesIdBack: identical(emiratesIdBack, _sentinel)
            ? this.emiratesIdBack
            : emiratesIdBack as UploadableAsset?,
        tradeLicence: identical(tradeLicence, _sentinel)
            ? this.tradeLicence
            : tradeLicence as UploadableAsset?,
        phase: phase ?? this.phase,
        extraction: extraction ?? this.extraction,
        failure: identical(failure, _sentinel)
            ? this.failure
            : failure as RegistrationFailure?,
      );

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
        email,
        onboardingToken,
        providerType,
        businessName,
        representativeName,
        fullName,
        emiratesIdFront,
        emiratesIdBack,
        tradeLicence,
        phase,
        extraction,
        failure,
      ];
}
