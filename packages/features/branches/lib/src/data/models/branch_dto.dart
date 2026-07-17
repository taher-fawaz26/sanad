import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';

class BranchDto {
  const BranchDto({
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
    this.servingAreaPlaceIds,
    this.servingAreaNames,
    this.serviceNames,
    this.createdAt,
  });

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    // --- Branch manager ---
    final manager = json['branchManager'];
    String? managerId;
    String? managerName;
    if (manager is Map<String, dynamic>) {
      managerId = manager['id'] as String?;
      // API returns `name`; older shapes had `fullName` or nested `workerInfo`.
      final workerInfo = manager['workerInfo'] as Map<String, dynamic>?;
      managerName = workerInfo?['fullName'] as String? ??
          manager['fullName'] as String? ??
          manager['name'] as String?;
    }

    // --- Availability ---
    final availabilityJson = json['availability'];
    List<BranchAvailabilityDto>? availability;
    if (availabilityJson is List) {
      availability = availabilityJson
          .map((e) => BranchAvailabilityDto.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // --- Serving areas ---
    // The API returns a `servingAreas` array of objects with placeId + nameEn.
    // Also support legacy `servingAreaPlaceIds` flat string list.
    List<String>? servingAreaPlaceIds;
    List<String>? servingAreaNames;

    final servingAreasJson = json['servingAreas'];
    if (servingAreasJson is List && servingAreasJson.isNotEmpty) {
      servingAreaPlaceIds = servingAreasJson
          .map((e) => (e as Map<String, dynamic>)['placeId'] as String? ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      servingAreaNames = servingAreasJson
          .map((e) => (e as Map<String, dynamic>)['nameEn'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    } else {
      final legacyIds = json['servingAreaPlaceIds'];
      if (legacyIds is List) {
        servingAreaPlaceIds = legacyIds.cast<String>();
      }
    }

    // --- Services ---
    final servicesJson = json['services'];
    List<String>? serviceNames;
    if (servicesJson is List && servicesJson.isNotEmpty) {
      serviceNames = servicesJson
          .map((e) =>
              (e as Map<String, dynamic>)['serviceNameEn'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
    }

    // --- City ---
    // API returns city as an object `{ nameEn, nameAr, ... }`.
    // Fall back to a plain string for backward compatibility.
    final cityRaw = json['city'];
    final String city;
    if (cityRaw is Map<String, dynamic>) {
      city = cityRaw['nameEn'] as String? ?? cityRaw['nameAr'] as String? ?? '';
    } else {
      city = cityRaw as String? ?? '';
    }

    // --- Status → isAvailable ---
    // API uses `"ACTIVE"` / `"MAINTENANCE"`.
    // Fall back to legacy `isAvailable` bool field if present.
    final statusStr = json['status'] as String?;
    final bool isAvailable;
    if (statusStr != null) {
      isAvailable = statusStr == 'ACTIVE';
    } else {
      isAvailable = json['isAvailable'] as bool? ?? true;
    }

    return BranchDto(
      id: json['id'] as String,
      branchName: json['branchName'] as String,
      branchAddress: json['branchAddress'] as String? ?? '',
      city: city,
      branchPhone: json['branchPhone'] as String? ?? '',
      isAvailable: isAvailable,
      availabilityMode: BranchAvailabilityMode.fromApiString(
        json['availabilityMode'] as String?,
      ),
      branchManagerId: managerId,
      branchManagerName: managerName,
      lat: _numericField(json['lat']),
      lng: _numericField(json['lng']),
      radiusKm: _numericField(json['radiusKm']),
      googleMapsLink: json['googleMapsLink'] as String?,
      socialMediaLink: json['socialMediaLink'] as String?,
      availability: availability,
      servingAreaPlaceIds: servingAreaPlaceIds,
      servingAreaNames: servingAreaNames,
      serviceNames: serviceNames,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  final String id;
  final String branchName;
  final String branchAddress;
  final String city;
  final String branchPhone;
  final bool isAvailable;
  final BranchAvailabilityMode availabilityMode;
  final String? branchManagerId;
  final String? branchManagerName;
  final double? lat;
  final double? lng;
  final double? radiusKm;
  final String? googleMapsLink;
  final String? socialMediaLink;
  final List<BranchAvailabilityDto>? availability;
  final List<String>? servingAreaPlaceIds;
  final List<String>? servingAreaNames;
  final List<String>? serviceNames;
  final DateTime? createdAt;

  BranchEntity toDomain() => BranchEntity(
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
        availability: availability?.map((a) => a.toDomain()).toList(),
        servingAreaPlaceIds: servingAreaPlaceIds,
        servingAreaNames: servingAreaNames,
        serviceNames: serviceNames,
        createdAt: createdAt,
      );
}

/// Parses a numeric field that the API may send as a [num] or as a [String].
double? _numericField(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
