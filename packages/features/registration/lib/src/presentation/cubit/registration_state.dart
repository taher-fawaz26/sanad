import 'package:asset_picker/asset_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:registration/src/data/models/extraction_result.dart';

/// Account type the registering user selects on the third step.
enum RegistrationAccountType { organization, individual }

/// Lifecycle of the (simulated) "AI extraction" step.
enum ExtractionStatus { idle, extracting, done }

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
    this.accountType,
    this.businessName = '',
    this.representativeName = '',
    this.fullName = '',
    this.emiratesIdFront,
    this.emiratesIdBack,
    this.tradeLicence,
    this.extractionStatus = ExtractionStatus.idle,
    this.extraction,
    this.lastUploadFailure,
  });

  final String email;

  /// Short-lived token issued by `auth/email/verify` for a new user; used to
  /// authorize the profile-creation calls that complete onboarding.
  final String? onboardingToken;

  final RegistrationAccountType? accountType;

  // Organization path.
  final String businessName;
  final String representativeName;

  // Individual path.
  final String fullName;

  // Captured documents (upload pipeline state).
  final UploadableAsset? emiratesIdFront;
  final UploadableAsset? emiratesIdBack;
  final UploadableAsset? tradeLicence;

  // Async step status.
  final ExtractionStatus extractionStatus;
  final ExtractionResult? extraction;

  /// Last upload failure message key / prose for the page to snackbar once.
  final String? lastUploadFailure;

  bool get isOrganization =>
      accountType == RegistrationAccountType.organization;

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
    RegistrationAccountType? accountType,
    String? businessName,
    String? representativeName,
    String? fullName,
    Object? emiratesIdFront = _sentinel,
    Object? emiratesIdBack = _sentinel,
    Object? tradeLicence = _sentinel,
    ExtractionStatus? extractionStatus,
    ExtractionResult? extraction,
    Object? lastUploadFailure = _sentinel,
  }) =>
      RegistrationState(
        email: email ?? this.email,
        onboardingToken: onboardingToken ?? this.onboardingToken,
        accountType: accountType ?? this.accountType,
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
        extractionStatus: extractionStatus ?? this.extractionStatus,
        extraction: extraction ?? this.extraction,
        lastUploadFailure: identical(lastUploadFailure, _sentinel)
            ? this.lastUploadFailure
            : lastUploadFailure as String?,
      );

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
        email,
        onboardingToken,
        accountType,
        businessName,
        representativeName,
        fullName,
        emiratesIdFront,
        emiratesIdBack,
        tradeLicence,
        extractionStatus,
        extraction,
        lastUploadFailure,
      ];
}
