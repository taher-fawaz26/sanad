import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:core/core.dart';

class BranchDto extends BranchEntity implements EntityConverter<BranchEntity> {
  const BranchDto({
    required super.id,
    required super.branchName,
    required super.branchAddress,
    required super.city,
    required super.branchPhone,
    required super.isAvailable,
    required super.availabilityMode,
    super.branchManagerId,
    super.branchManagerName,
    super.lat,
    super.lng,
    super.radiusKm,
    super.googleMapsLink,
    super.socialMediaLink,
    super.availability,
    super.createdAt,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    final manager = json['branchManager'];
    String? managerId;
    String? managerName;
    if (manager is Map<String, dynamic>) {
      managerId = manager['id'] as String?;
      // Manager object may contain worker info; extract display name if present.
      final workerInfo = manager['workerInfo'] as Map<String, dynamic>?;
      managerName = workerInfo?['fullName'] as String? ??
          manager['fullName'] as String?;
    }

    final availabilityJson = json['availability'];
    List<BranchAvailabilityDto>? availability;
    if (availabilityJson is List) {
      availability = availabilityJson
          .map(
            (e) =>
                BranchAvailabilityDto.fromJson(e as Map<String, dynamic>),
          )
          .toList();
    }

    return BranchDto(
      id: json['id'] as String,
      branchName: json['branchName'] as String,
      branchAddress: json['branchAddress'] as String? ?? '',
      city: json['city'] as String? ?? '',
      branchPhone: json['branchPhone'] as String? ?? '',
      isAvailable: json['isAvailable'] as bool? ?? true,
      availabilityMode:
          json['availabilityMode'] as String? ?? 'CORE_HOURS',
      branchManagerId: managerId,
      branchManagerName: managerName,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      radiusKm: (json['radiusKm'] as num?)?.toDouble(),
      googleMapsLink: json['googleMapsLink'] as String?,
      socialMediaLink: json['socialMediaLink'] as String?,
      availability: availability,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  BranchEntity toEntity() => BranchEntity(
        id: id,
        branchName: branchName,
        branchAddress: branchAddress,
        city: city,
        branchPhone: branchPhone,
        isAvailable: isAvailable,
        availabilityMode: availabilityMode,
        branchManagerId: branchManagerId,
        branchManagerName: branchManagerName,
        lat: lat,
        lng: lng,
        radiusKm: radiusKm,
        googleMapsLink: googleMapsLink,
        socialMediaLink: socialMediaLink,
        availability: availability,
        createdAt: createdAt,
      );
}
