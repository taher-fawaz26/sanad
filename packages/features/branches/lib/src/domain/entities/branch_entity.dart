import 'package:branches/src/domain/entities/branch_availability_entity.dart';
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
    this.branchManagerId,
    this.branchManagerName,
    this.lat,
    this.lng,
    this.radiusKm,
    this.googleMapsLink,
    this.socialMediaLink,
    this.availability,
    this.createdAt,
  });

  final String id;
  final String branchName;
  final String branchAddress;
  final String city;
  final String branchPhone;

  /// `true` = Active, `false` = Maintenance.
  final bool isAvailable;

  /// API enum value: `"CORE_HOURS"` or `"CUSTOM"`.
  final String availabilityMode;

  final String? branchManagerId;
  final String? branchManagerName;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final List<BranchAvailabilityEntity>? availability;
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
        branchManagerId,
        branchManagerName,
        lat,
        lng,
        radiusKm,
        googleMapsLink,
        socialMediaLink,
        availability,
        createdAt,
      ];
}
