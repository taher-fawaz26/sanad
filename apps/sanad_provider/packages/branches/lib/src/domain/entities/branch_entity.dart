import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/entities/branch_worker_entity.dart';
import 'package:equatable/equatable.dart';
import 'package:maps/maps.dart' show ServingArea;

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
    this.cityId,
    this.cityNameAr,
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
    this.servingAreas = const [],
    this.serviceIds,
    this.serviceNames,
    this.workers = const [],
    this.createdAt,
  });

  final String id;
  final String branchName;
  final String branchAddress;

  /// City display name (English). See [cityId] for the identifier.
  final String city;
  final String branchPhone;

  /// `true` = Active (`ACTIVE`), `false` = Maintenance (`MAINTENANCE`).
  final bool isAvailable;

  final BranchAvailabilityMode availabilityMode;

  final BranchType branchType;

  /// Backend city identifier (needed to prefill / update the branch's city).
  final String? cityId;

  /// City display name (Arabic), when returned by the API.
  final String? cityNameAr;

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

  /// Serving areas with full geometry (placeId + name + LatLng), used to
  /// prefill the coverage editor. Parallels [servingAreaPlaceIds].
  final List<ServingArea> servingAreas;

  /// Backend service identifiers assigned to this branch (parallels
  /// [serviceNames]). Needed to prefill / update the branch's services.
  final List<String>? serviceIds;

  /// Service names assigned to this branch (e.g. ["Car Repair"]).
  final List<String>? serviceNames;

  /// Workers assigned to this branch, as returned by GET /branches/{id}.
  final List<BranchWorkerEntity> workers;

  final DateTime? createdAt;

  /// Convenience display: `"Address, City"`.
  String get displayAddress => '$branchAddress, $city';

  /// Returns a copy with the given fields replaced. Used to apply a single
  /// section's edits on top of the current branch before rebuilding the full
  /// PATCH payload — see `AddBranchParamsMapper.fromBranch`.
  BranchEntity copyWith({
    String? branchName,
    String? branchAddress,
    String? city,
    String? branchPhone,
    bool? isAvailable,
    BranchAvailabilityMode? availabilityMode,
    BranchType? branchType,
    String? cityId,
    String? cityNameAr,
    String? branchManagerId,
    String? branchManagerName,
    double? lat,
    double? lng,
    double? radiusKm,
    String? googleMapsLink,
    String? socialMediaLink,
    List<BranchAvailabilityEntity>? availability,
    List<String>? servingAreaPlaceIds,
    List<String>? servingAreaNames,
    List<ServingArea>? servingAreas,
    List<String>? serviceIds,
    List<String>? serviceNames,
    List<BranchWorkerEntity>? workers,
    DateTime? createdAt,
  }) => BranchEntity(
    id: id,
    branchName: branchName ?? this.branchName,
    branchAddress: branchAddress ?? this.branchAddress,
    city: city ?? this.city,
    branchPhone: branchPhone ?? this.branchPhone,
    isAvailable: isAvailable ?? this.isAvailable,
    availabilityMode: availabilityMode ?? this.availabilityMode,
    branchType: branchType ?? this.branchType,
    cityId: cityId ?? this.cityId,
    cityNameAr: cityNameAr ?? this.cityNameAr,
    branchManagerId: branchManagerId ?? this.branchManagerId,
    branchManagerName: branchManagerName ?? this.branchManagerName,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
    radiusKm: radiusKm ?? this.radiusKm,
    googleMapsLink: googleMapsLink ?? this.googleMapsLink,
    socialMediaLink: socialMediaLink ?? this.socialMediaLink,
    availability: availability ?? this.availability,
    servingAreaPlaceIds: servingAreaPlaceIds ?? this.servingAreaPlaceIds,
    servingAreaNames: servingAreaNames ?? this.servingAreaNames,
    servingAreas: servingAreas ?? this.servingAreas,
    serviceIds: serviceIds ?? this.serviceIds,
    serviceNames: serviceNames ?? this.serviceNames,
    workers: workers ?? this.workers,
    createdAt: createdAt ?? this.createdAt,
  );

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
    cityId,
    cityNameAr,
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
    servingAreas,
    serviceIds,
    serviceNames,
    workers,
    createdAt,
  ];
}
