import 'package:branches/src/domain/entities/branch_availability_entity.dart';
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

class CreateBranchParams extends Equatable {
  const CreateBranchParams({
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

class UpdateBranchParams extends Equatable {
  const UpdateBranchParams({
    required this.id,
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

  final String id;
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
  final String? availabilityMode;
  final List<BranchAvailabilityEntity>? availability;
  final List<String>? serviceIds;
  final List<String>? servingAreaPlaceIds;

  @override
  List<Object?> get props => [
        id,
        branchName,
        branchAddress,
        city,
        branchPhone,
        branchManagerId,
        isAvailable,
        availabilityMode,
      ];
}

class DeleteBranchParams extends Equatable {
  const DeleteBranchParams({required this.id});

  final String id;

  @override
  List<Object?> get props => [id];
}
