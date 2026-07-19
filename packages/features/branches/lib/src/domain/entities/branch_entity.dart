import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/entities/branch_worker_entity.dart';
import 'package:equatable/equatable.dart';

class BranchEntity extends Equatable {
  const BranchEntity({
    required this.id,
    required this.branchName,
    required this.branchAddress,
    required this.city,
    required this.branchPhone,
    required this.isAvailable,
    required this.availabilityMode,
    this.branchType = BranchType.mainBranch,
    this.branchManagerId,
    this.branchManagerName,
    this.lat,
    this.lng,
    this.radiusKm,
    this.googleMapsLink,
    this.socialMediaLink,
    this.availability,
    this.servingAreaPlaceIds,
    this.servingAreaNames,
    this.serviceNames,
    this.workers = const [],
    this.createdAt,
  });

  final String id;
  final String branchName;
  final String branchAddress;
  final String city;
  final String branchPhone;

  /// `true` = Active (`ACTIVE`), `false` = Maintenance (`MAINTENANCE`).
  final bool isAvailable;

  final BranchAvailabilityMode availabilityMode;

  final BranchType branchType;

  final String? branchManagerId;
  final String? branchManagerName;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final List<BranchAvailabilityEntity>? availability;

  /// Place IDs for serving areas (used for map / coverage display).
  final List<String>? servingAreaPlaceIds;

  /// Human-readable names for serving areas (e.g. "Ras Al-Khaimah").
  final List<String>? servingAreaNames;

  /// Service names assigned to this branch (e.g. ["Car Repair"]).
  final List<String>? serviceNames;

  /// Workers assigned to this branch, as returned by GET /branches/{id}.
  final List<BranchWorkerEntity> workers;

  final DateTime? createdAt;

  /// Convenience display: `"Address, City"`.
  String get displayAddress => '$branchAddress, $city';

  @override
  List<Object?> get props => [
    id,
    branchName,
    branchAddress,
    city,
    branchPhone,
    isAvailable,
    availabilityMode,
    branchType,
    branchManagerId,
    branchManagerName,
    lat,
    lng,
    radiusKm,
    googleMapsLink,
    socialMediaLink,
    availability,
    servingAreaPlaceIds,
    servingAreaNames,
    serviceNames,
    workers,
    createdAt,
  ];
}
