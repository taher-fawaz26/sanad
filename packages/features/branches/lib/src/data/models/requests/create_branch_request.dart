import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:equatable/equatable.dart';

class CreateBranchRequest extends Equatable {
  const CreateBranchRequest({
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
    this.isAvailable = true,
    this.availabilityMode = 'CORE_HOURS',
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
  final bool isAvailable;
  final String availabilityMode;
  final List<BranchAvailabilityEntity>? availability;
  final List<String>? serviceIds;
  final List<String>? servingAreaPlaceIds;

  Map<String, dynamic> toMap() {
    final body = <String, dynamic>{
      'branchName': branchName,
      'branchAddress': branchAddress,
      'city': city,
      'branchPhone': branchPhone,
      'isAvailable': isAvailable,
      'availabilityMode': availabilityMode,
    };
    if (branchManagerId != null) body['branchManagerId'] = branchManagerId;
    if (lat != null) body['lat'] = lat;
    if (lng != null) body['lng'] = lng;
    if (radiusKm != null) body['radiusKm'] = radiusKm;
    if (googleMapsLink != null) body['googleMapsLink'] = googleMapsLink;
    if (socialMediaLink != null) body['socialMediaLink'] = socialMediaLink;
    if (availability != null) {
      body['availability'] = availability!
          .map(
            (a) => {
              'day': a.day,
              'slots': a.slots
                  .map((s) => {'from': s.from, 'to': s.to})
                  .toList(),
            },
          )
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
        branchAddress,
        city,
        branchPhone,
        branchManagerId,
        isAvailable,
        availabilityMode,
      ];
}
