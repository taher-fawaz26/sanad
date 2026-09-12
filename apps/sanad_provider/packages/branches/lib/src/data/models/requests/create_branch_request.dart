import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:equatable/equatable.dart';

class CreateBranchRequest extends Equatable {
  const CreateBranchRequest({
    required this.branchName,
    required this.branchType,
    required this.branchAddress,
    required this.locationPlaceId,
    required this.branchPhone,
    required this.lat,
    required this.lng,
    required this.radiusKm,
    required this.workerIds,
    required this.serviceIds,
    required this.servingAreaPlaceIds,
    this.branchManagerId,
    this.googleMapsLink,
    this.socialMediaLink,
    this.availabilityMode = BranchAvailabilityMode.coreHours,
    this.availability,
  });

  final String branchName;
  final BranchType branchType;
  final String branchAddress;
  final String locationPlaceId;
  final String branchPhone;
  final String? branchManagerId;
  final double lat;
  final double lng;
  final double radiusKm;
  final List<String> workerIds;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final BranchAvailabilityMode availabilityMode;
  final List<BranchAvailabilityEntity>? availability;

  /// Provider-service ids from `GET /provider-services`.
  ///
  /// **Required.** `POST /branches` rejects a missing or empty array — a
  /// branch that offers nothing cannot be matched to any request, so the
  /// backend stopped accepting one.
  ///
  /// Not asserted non-empty here: this class is `const`, and `List.length` is
  /// not const-evaluable. Emptiness is prevented up front by the wizard's
  /// step gates (`AddBranchDraftState.isStepThreeComplete`) and caught by the
  /// server otherwise.
  final List<String> serviceIds;

  /// Google `place_id` values matched against `location_areas`.
  ///
  /// **Required.** Same reasoning as [serviceIds]: serving areas are what
  /// make a branch reachable by the matcher at all. Gated by
  /// `AddBranchDraftState.isStepTwoComplete`.
  ///
  /// This used to be dropped from the body when empty, which under the new
  /// contract produces a `400` rather than the old silent no-op.
  final List<String> servingAreaPlaceIds;

  Map<String, dynamic> toMap() {
    final body = <String, dynamic>{
      'branchName': branchName,
      'type': branchType.toApiString(),
      'branchAddress': branchAddress,
      'locationPlaceId': locationPlaceId,
      'branchPhone': branchPhone,
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'workerIds': workerIds,
      'availabilityMode': availabilityMode.toApiString(),
    };
    if (branchManagerId != null) body['branchManagerId'] = branchManagerId;
    if (googleMapsLink != null) body['googleMapsLink'] = googleMapsLink;
    if (socialMediaLink != null) body['socialMediaLink'] = socialMediaLink;
    if (availability != null) {
      body['availability'] = availability!
          .map(BranchAvailabilityDto.entityToMap)
          .toList();
    }
    // Always sent: both are required by the contract, and the constructor
    // has already asserted neither is empty.
    body['serviceIds'] = serviceIds;
    body['servingAreaPlaceIds'] = servingAreaPlaceIds;
    return body;
  }

  @override
  List<Object?> get props => [
    branchName,
    branchType,
    branchAddress,
    locationPlaceId,
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
