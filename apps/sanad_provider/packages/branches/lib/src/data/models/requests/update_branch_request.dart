import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:equatable/equatable.dart';

/// PATCH request body for updating a branch.
///
/// Only non-null optional fields are serialized. Status changes use the
/// dedicated [PATCH /branches/{id}/status] endpoint — not this request.
class UpdateBranchRequest extends Equatable {
  const UpdateBranchRequest({
    required this.branchName,
    required this.branchAddress,
    required this.branchPhone,
    this.branchType,
    this.locationPlaceId,
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

  final String branchName;
  final String branchAddress;
  final String branchPhone;

  /// Only serialized when changing the branch type.
  final BranchType? branchType;

  /// Google Places Autocomplete place ID. When non-null, [lat] and [lng] are
  /// serialized together with it — the backend requires all three as a unit.
  final String? locationPlaceId;

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

  /// Only serialized when changing assigned workers.
  final List<String>? workerIds;

  Map<String, dynamic> toMap() {
    final body = <String, dynamic>{
      'branchName': branchName,
      'branchAddress': branchAddress,
      'branchPhone': branchPhone,
    };
    if (branchType != null) body['type'] = branchType!.toApiString();
    if (locationPlaceId != null) {
      body['locationPlaceId'] = locationPlaceId;
      if (lat != null) body['lat'] = lat;
      if (lng != null) body['lng'] = lng;
    }
    if (branchManagerId != null) body['branchManagerId'] = branchManagerId;
    if (radiusKm != null) body['radiusKm'] = radiusKm;
    if (googleMapsLink != null) body['googleMapsLink'] = googleMapsLink;
    if (socialMediaLink != null) body['socialMediaLink'] = socialMediaLink;
    if (availabilityMode != null) {
      body['availabilityMode'] = availabilityMode!.toApiString();
    }
    if (availability != null) {
      body['availability'] = availability!
          .map(BranchAvailabilityDto.entityToMap)
          .toList();
    }
    // Omitting either field leaves it untouched server-side; sending an
    // explicitly **empty** array is now rejected with a `400`. So an empty
    // list means "no change", never "detach everything" — the backend offers
    // no way to express the latter, and a branch with no services or no
    // serving areas cannot be matched to anything.
    if (serviceIds != null && serviceIds!.isNotEmpty) {
      body['serviceIds'] = serviceIds;
    }
    if (servingAreaPlaceIds != null && servingAreaPlaceIds!.isNotEmpty) {
      body['servingAreaPlaceIds'] = servingAreaPlaceIds;
    }
    if (workerIds != null) body['workerIds'] = workerIds;
    return body;
  }

  @override
  List<Object?> get props => [
    branchName,
    branchAddress,
    branchPhone,
    branchType,
    locationPlaceId,
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
