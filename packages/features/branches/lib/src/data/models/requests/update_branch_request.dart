import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:equatable/equatable.dart';

class UpdateBranchRequest extends Equatable {
  const UpdateBranchRequest({
    required this.branchName,
    required this.branchAddress,
    required this.city,
    required this.branchPhone,
    this.branchManagerId,
    this.lat,
    this.lng,
    this.radiusKm,
    this.googleMapsLink,
    this.socialMediaLink,
    this.isAvailable,
    this.availabilityMode,
    this.availability,
    this.serviceIds,
    this.servingAreaPlaceIds,
  });

  final String branchName;
  final String branchAddress;
  final String city;
  final String branchPhone;
  final String? branchManagerId;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final bool? isAvailable;
  final BranchAvailabilityMode? availabilityMode;
  final List<BranchAvailabilityEntity>? availability;
  final List<String>? serviceIds;
  final List<String>? servingAreaPlaceIds;

  Map<String, dynamic> toMap() {
    final body = <String, dynamic>{
      'branchName': branchName,
      'branchAddress': branchAddress,
      'city': city,
      'branchPhone': branchPhone,
    };
    if (branchManagerId != null) body['branchManagerId'] = branchManagerId;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (radiusKm != null) body['radiusKm'] = radiusKm;
    if (googleMapsLink != null) body['googleMapsLink'] = googleMapsLink;
    if (socialMediaLink != null) body['socialMediaLink'] = socialMediaLink;
    if (isAvailable != null) body['isAvailable'] = isAvailable;
    if (availabilityMode != null) {
      body['availabilityMode'] = availabilityMode!.toApiString();
    }
    if (availability != null) {
      body['availability'] =
          availability!.map(BranchAvailabilityDto.entityToMap).toList();
    }
    if (serviceIds != null) body['serviceIds'] = serviceIds;
    if (servingAreaPlaceIds != null && servingAreaPlaceIds!.isNotEmpty) {
      body['servingAreaPlaceIds'] = servingAreaPlaceIds;
    }
    return body;
  }

  @override
  List<Object?> get props => [
        branchName,
        branchAddress,
        city,
        branchPhone,
        branchManagerId,
        lat,
        lng,
        radiusKm,
        googleMapsLink,
        socialMediaLink,
        isAvailable,
        availabilityMode,
        availability,
        serviceIds,
        servingAreaPlaceIds,
      ];
}
