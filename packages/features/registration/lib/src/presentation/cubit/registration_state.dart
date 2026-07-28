import 'package:asset_picker/asset_picker.dart';
import 'package:equatable/equatable.dart';
import 'package:registration/src/data/models/extraction_result.dart';

/// Account type the registering user selects on the third step.
enum RegistrationAccountType { organization, individual }

/// Lifecycle of the (simulated) OTP verification request.
enum OtpStatus { idle, verifying, error }

/// Lifecycle of the (simulated) "AI extraction" step.
enum ExtractionStatus { idle, extracting, done }

/// Immutable state carried across the whole sign-up flow by the cubit.
///
/// A single instance lives for the duration of the `/signup` shell, so every
/// step reads and contributes to the same object.
class RegistrationState extends Equatable {
  const RegistrationState({
    this.email = '',
    this.accountType,
    this.businessName = '',
    this.representativeName = '',
    this.fullName = '',
    this.emiratesIdFront,
    this.emiratesIdBack,
    this.tradeLicence,
    this.otpStatus = OtpStatus.idle,
    this.extractionStatus = ExtractionStatus.idle,
    this.extraction,
  });

  final String email;
  final RegistrationAccountType? accountType;

  // Organization path.
  final String businessName;
  final String representativeName;

  // Individual path.
  final String fullName;

  // Captured documents.
  final PickedAsset? emiratesIdFront;
  final PickedAsset? emiratesIdBack;
  final PickedAsset? tradeLicence;

  // Async step status.
  final OtpStatus otpStatus;
  final ExtractionStatus extractionStatus;
  final ExtractionResult? extraction;

  bool get isOrganization =>
      accountType == RegistrationAccountType.organization;

  /// True once both Emirates ID sides have been captured.
  bool get hasBothIdSides =>
      emiratesIdFront != null && emiratesIdBack != null;

  RegistrationState copyWith({
    String? email,
    RegistrationAccountType? accountType,
    String? businessName,
    String? representativeName,
    String? fullName,
    PickedAsset? emiratesIdFront,
    PickedAsset? emiratesIdBack,
    PickedAsset? tradeLicence,
    OtpStatus? otpStatus,
    ExtractionStatus? extractionStatus,
    ExtractionResult? extraction,
  }) =>
      RegistrationState(
        email: email ?? this.email,
        accountType: accountType ?? this.accountType,
        businessName: businessName ?? this.businessName,
        representativeName: representativeName ?? this.representativeName,
        fullName: fullName ?? this.fullName,
        emiratesIdFront: emiratesIdFront ?? this.emiratesIdFront,
        emiratesIdBack: emiratesIdBack ?? this.emiratesIdBack,
        tradeLicence: tradeLicence ?? this.tradeLicence,
        otpStatus: otpStatus ?? this.otpStatus,
        extractionStatus: extractionStatus ?? this.extractionStatus,
        extraction: extraction ?? this.extraction,
      );

  @override
  List<Object?> get props => [
        email,
        accountType,
        businessName,
        representativeName,
        fullName,
        emiratesIdFront,
        emiratesIdBack,
        tradeLicence,
        otpStatus,
        extractionStatus,
        extraction,
      ];
}
