import 'package:auth/src/domain/entities/worker_status.dart';
import 'package:auth/src/domain/enums/worker_type.dart';
import 'package:equatable/equatable.dart';

/// Base type for the Swagger `oneOf` auth profile payload.
///
/// Concrete models in `data/` extend these entities (inheritance, no mapper).
/// Kept as [abstract] (not sealed) so data-layer subtypes may live in other
/// libraries within the package.
abstract class AuthProfileEntity extends Equatable {
  const AuthProfileEntity();
}

/// Client account profile.
class ClientProfileEntity extends AuthProfileEntity {
  const ClientProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.emiratesId,
  });

  final String id;
  final String fullName;
  final String email;
  final String emiratesId;

  @override
  List<Object?> get props => [id, fullName, email, emiratesId];
}

/// Individual (solo) provider profile.
class IndividualProviderProfileEntity extends AuthProfileEntity {
  const IndividualProviderProfileEntity({
    required this.id,
    required this.fullName,
    required this.email,
    required this.emiratesId,
    required this.isReviewed,
  });

  final String id;
  final String fullName;
  final String email;
  final String emiratesId;
  final bool isReviewed;

  @override
  List<Object?> get props => [id, fullName, email, emiratesId, isReviewed];
}

/// Company / organization provider profile.
class CompanyProviderProfileEntity extends AuthProfileEntity {
  const CompanyProviderProfileEntity({
    required this.id,
    required this.businessName,
    required this.businessEmail,
    required this.representativeFullName,
    required this.representativeEmail,
    required this.isReviewed,
    this.tradeLicenseNumber,
    this.representativeEmiratesId,
    this.emiratesIdFrontId,
    this.emiratesIdBackId,
    this.tradeLicenseId,
  });

  final String id;
  final String businessName;
  final String businessEmail;

  /// Nullable per Swagger `CompanyProviderAuthProfileResponseDto`.
  final String? tradeLicenseNumber;
  final String representativeFullName;
  final String representativeEmail;

  /// Nullable per Swagger `CompanyProviderAuthProfileResponseDto`.
  final String? representativeEmiratesId;

  /// Document media IDs — omitted or null on some verify payloads.
  final String? emiratesIdFrontId;
  final String? emiratesIdBackId;
  final String? tradeLicenseId;
  final bool isReviewed;

  @override
  List<Object?> get props => [
    id,
    businessName,
    businessEmail,
    tradeLicenseNumber,
    representativeFullName,
    representativeEmail,
    representativeEmiratesId,
    emiratesIdFrontId,
    emiratesIdBackId,
    tradeLicenseId,
    isReviewed,
  ];
}

/// Worker account profile.
class WorkerProfileEntity extends AuthProfileEntity {
  const WorkerProfileEntity({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.jobTitle,
    required this.type,
    required this.status,
  });

  final String id;
  final String name;
  final String phoneNumber;
  final String jobTitle;
  final WorkerType type;
  final WorkerStatus status;

  @override
  List<Object?> get props => [id, name, phoneNumber, jobTitle, type, status];
}
