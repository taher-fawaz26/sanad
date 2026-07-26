import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:equatable/equatable.dart';

class GetBranchesParams extends Equatable {
  const GetBranchesParams({this.page = 1, this.limit = 20});

  final int page;
  final int limit;

  @override
  List<Object?> get props => [page, limit];
}

class GetBranchParams extends Equatable {
  const GetBranchParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}

/// Validated submission command for creating a branch.
///
/// All fields required by [CreateBranchDto] are non-nullable here.
/// [workerIds] must be non-empty (OpenAPI minItems: 1).
class CreateBranchParams extends Equatable {
  const CreateBranchParams({
    required this.branchName,
    required this.branchType,
    required this.branchAddress,
    required this.cityId,
    required this.branchPhone,
    required this.branchManagerId,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.workerIds,
    this.googleMapsLink,
    this.socialMediaLink,
    this.availabilityMode = BranchAvailabilityMode.coreHours,
    this.availability,
    this.serviceIds,
    this.servingAreaPlaceIds,
  });

  final String branchName;
  final BranchType branchType;
  final String branchAddress;
  final String cityId;
  final String branchPhone;
  final String branchManagerId;
  final double lat;
  final double lng;
  final double radiusKm;

  /// At least one worker ID is required by the API (minItems: 1).
  final List<String> workerIds;

  final String? googleMapsLink;
  final String? socialMediaLink;
  final BranchAvailabilityMode availabilityMode;
  final List<BranchAvailabilityEntity>? availability;
  final List<String>? serviceIds;
  final List<String>? servingAreaPlaceIds;

  @override
  List<Object?> get props => [
    branchName,
    branchType,
    branchAddress,
    cityId,
    branchPhone,
    branchManagerId,
    lat,
    lng,
    radiusKm,
    workerIds,
    googleMapsLink,
    socialMediaLink,
    availabilityMode,
    availability,
    serviceIds,
    servingAreaPlaceIds,
  ];
}

/// PATCH parameters for updating a branch.
///
/// All fields are optional (PATCH semantics). Status changes go through
/// [UpdateBranchStatusParams] / [PATCH /branches/{id}/status].
class UpdateBranchParams extends Equatable {
  const UpdateBranchParams({
    required this.id,
    required this.branchName,
    required this.branchAddress,
    required this.branchPhone,
    this.branchType,
    this.cityId,
    this.branchManagerId,
    this.lat,
    this.lng,
    this.radiusKm,
    this.googleMapsLink,
    this.socialMediaLink,
    this.availabilityMode,
    this.availability,
    this.serviceIds,
    this.servingAreaPlaceIds,
    this.workerIds,
  });

  final String id;
  final String branchName;
  final String branchAddress;
  final String branchPhone;

  /// Optional during PATCH. Provide only when changing the branch type.
  final BranchType? branchType;

  /// Optional during PATCH. Provide only when changing the branch city.
  final String? cityId;

  final String? branchManagerId;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final BranchAvailabilityMode? availabilityMode;
  final List<BranchAvailabilityEntity>? availability;
  final List<String>? serviceIds;
  final List<String>? servingAreaPlaceIds;

  /// Optional during PATCH. Provide only when changing assigned workers.
  final List<String>? workerIds;

  @override
  List<Object?> get props => [
    id,
    branchName,
    branchAddress,
    branchPhone,
    branchType,
    cityId,
    branchManagerId,
    lat,
    lng,
    radiusKm,
    googleMapsLink,
    socialMediaLink,
    availabilityMode,
    availability,
    serviceIds,
    servingAreaPlaceIds,
    workerIds,
  ];
}

class UpdateBranchStatusParams extends Equatable {
  const UpdateBranchStatusParams({required this.id, required this.isAvailable});

  final String id;

  /// `true` → sets status to `ACTIVE`; `false` → sets status to `MAINTENANCE`.
  final bool isAvailable;

  String get statusString => isAvailable ? 'ACTIVE' : 'MAINTENANCE';

  @override
  List<Object?> get props => [id, isAvailable];
}

class GetBranchManagersParams extends Equatable {
  const GetBranchManagersParams({
    this.query,
    this.page = 1,
    this.limit = 20,
  });

  /// Optional search query — `null` means no filter.
  final String? query;
  final int page;
  final int limit;

  @override
  List<Object?> get props => [query, page, limit];
}

class DeleteBranchParams extends Equatable {
  const DeleteBranchParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
