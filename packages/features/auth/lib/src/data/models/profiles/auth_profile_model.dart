import 'package:auth/src/domain/entities/auth_profile_entity.dart';
import 'package:auth/src/domain/entities/worker_status.dart';
import 'package:auth/src/domain/enums/user_type.dart';
import 'package:auth/src/domain/enums/worker_type.dart';

/// Sealed, parsed variant of [AuthProfileEntity].
///
/// The backend's `profile` oneOf has exactly three wire shapes:
/// `ClientAuthProfileResponseDto`, `WorkerAuthProfileResponseDto`, and
/// `BusinessProviderAuthProfileResponseDto` — the latter shared by BOTH
/// [UserType.individualProvider] and [UserType.companyProvider] accounts.
/// There is no separate "individual provider" wire shape; the backend does
/// not distinguish them at this layer.
///
/// [fromJson] is the sole dispatcher, replacing the old `AuthProfileFactory`.
/// Kept `sealed` (not just abstract) so any switch over a parsed profile is
/// compiler-checked exhaustive against exactly these three variants.
sealed class AuthProfileModel extends AuthProfileEntity {
  const AuthProfileModel();

  static AuthProfileModel fromJson({
    required UserType userType,
    required Map<String, dynamic> json,
  }) {
    switch (userType) {
      case UserType.client:
        return ClientProfileModel.fromJson(json);
      case UserType.individualProvider:
      case UserType.companyProvider:
        return BusinessProviderProfileModel.fromJson(json);
      case UserType.worker:
        return WorkerProfileModel.fromJson(json);
      case UserType.admin:
        throw StateError(
          'UserType.admin has no AuthProfile payload in the API oneOf.',
        );
    }
  }

  /// Serializes this profile back to its wire shape.
  Map<String, dynamic> toJson();
}

/// Client account profile (`ClientAuthProfileResponseDto`). Every field is
/// required on the wire — a missing one is a genuine schema violation and
/// throws rather than being silently defaulted.
class ClientProfileModel extends AuthProfileModel {
  const ClientProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.emiratesId,
  });

  factory ClientProfileModel.fromJson(Map<String, dynamic> json) {
    return ClientProfileModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      emiratesId: json['emiratesId'] as String,
    );
  }

  final String id;
  final String fullName;
  final String email;
  final String emiratesId;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'email': email,
    'emiratesId': emiratesId,
  };

  @override
  List<Object?> get props => [id, fullName, email, emiratesId];
}

/// Worker account profile (`WorkerAuthProfileResponseDto`). Every field is
/// required on the wire.
class WorkerProfileModel extends AuthProfileModel {
  const WorkerProfileModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.jobTitle,
    required this.type,
    required this.status,
  });

  factory WorkerProfileModel.fromJson(Map<String, dynamic> json) {
    return WorkerProfileModel(
      id: json['id'] as String,
      name: json['name'] as String,
      phoneNumber: json['phoneNumber'] as String,
      jobTitle: json['jobTitle'] as String,
      type: WorkerType.fromString(json['type'] as String),
      status: WorkerStatus.fromString(json['status'] as String),
    );
  }

  final String id;
  final String name;
  final String phoneNumber;
  final String jobTitle;
  final WorkerType type;
  final WorkerStatus status;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'phoneNumber': phoneNumber,
    'jobTitle': jobTitle,
    'type': type.value,
    'status': status.value,
  };

  @override
  List<Object?> get props => [id, name, phoneNumber, jobTitle, type, status];
}

/// Provider profile (`BusinessProviderAuthProfileResponseDto`) — the single
/// shape shared by individual and company providers.
///
/// Every business field is nullable server-side: a freshly onboarded
/// provider has only `id` + `isReviewed` populated. Only `id` and
/// `isReviewed` are hard-cast (required per the DTO); the rest are optional
/// casts (`as String?`) — matching the schema exactly, not a blanket
/// defensive fallback.
class BusinessProviderProfileModel extends AuthProfileModel {
  const BusinessProviderProfileModel({
    required this.id,
    required this.isReviewed,
    this.businessName,
    this.businessEmail,
    this.businessPhone,
    this.tradeLicenseNumber,
  });

  factory BusinessProviderProfileModel.fromJson(Map<String, dynamic> json) {
    return BusinessProviderProfileModel(
      id: json['id'] as String,
      businessName: json['businessName'] as String?,
      businessEmail: json['businessEmail'] as String?,
      businessPhone: json['businessPhone'] as String?,
      tradeLicenseNumber: json['tradeLicenseNumber'] as String?,
      isReviewed: json['isReviewed'] as bool,
    );
  }

  final String id;
  final String? businessName;
  final String? businessEmail;
  final String? businessPhone;
  final String? tradeLicenseNumber;
  final bool isReviewed;

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'businessName': businessName,
    'businessEmail': businessEmail,
    'businessPhone': businessPhone,
    'tradeLicenseNumber': tradeLicenseNumber,
    'isReviewed': isReviewed,
  };

  @override
  List<Object?> get props => [
    id,
    businessName,
    businessEmail,
    businessPhone,
    tradeLicenseNumber,
    isReviewed,
  ];
}
