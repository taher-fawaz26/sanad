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
  final List<String> workerIds;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final BranchAvailabilityMode availabilityMode;
  final List<BranchAvailabilityEntity>? availability;
  final List<String>? serviceIds;
  final List<String>? servingAreaPlaceIds;

  Map<String, dynamic> toMap() {
    final body = <String, dynamic>{
      'branchName': branchName,
      'type': branchType.toApiString(),
      'branchAddress': branchAddress,
      'cityId': cityId,
      'branchPhone': branchPhone,
      'branchManagerId': branchManagerId,
      'lat': lat,
      'lng': lng,
      'radiusKm': radiusKm,
      'workerIds': workerIds,
      'availabilityMode': availabilityMode.toApiString(),
    };
    if (googleMapsLink != null) body['googleMapsLink'] = googleMapsLink;
    if (socialMediaLink != null) body['socialMediaLink'] = socialMediaLink;
    if (availability != null) {
      body['availability'] = availability!
          .map(BranchAvailabilityDto.entityToMap)
          .toList();
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
