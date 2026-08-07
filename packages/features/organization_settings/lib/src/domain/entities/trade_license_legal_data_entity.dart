import 'package:equatable/equatable.dart';
import 'package:organization_settings/src/domain/entities/media_entity.dart';

/// The company's trade license data, extracted by the backend from the
/// uploaded document — `TradeLicenseResponseDto`. Nullable at the profile
/// level (individual providers have no trade license); the entity itself is
/// always fully shaped when present.
class TradeLicenseLegalDataEntity extends Equatable {
  const TradeLicenseLegalDataEntity({
    required this.id,
    required this.isExpired,
    required this.isExpiringSoon,
    required this.createdAt,
    required this.updatedAt,
    this.licenseType,
    this.licenseCategory,
    this.licenseNumber,
    this.unifiedRegistrationNumber,
    this.unifiedLicenseNumber,
    this.establishmentDate,
    this.issuanceDate,
    this.expiryDate,
    this.legalForm,
    this.tradeNameEnglish,
    this.tradeNameArabic,
    this.document,
  });

  final String id;
  final String? licenseType;
  final String? licenseCategory;
  final String? licenseNumber;
  final String? unifiedRegistrationNumber;
  final String? unifiedLicenseNumber;

  /// ISO date string (e.g. `2015-03-10`).
  final String? establishmentDate;

  /// ISO date string (e.g. `2024-01-01`).
  final String? issuanceDate;

  /// ISO date string (e.g. `2026-12-31`).
  final String? expiryDate;
  final String? legalForm;
  final String? tradeNameEnglish;
  final String? tradeNameArabic;
  final bool isExpired;
  final bool isExpiringSoon;
  final MediaEntity? document;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    licenseType,
    licenseCategory,
    licenseNumber,
    unifiedRegistrationNumber,
    unifiedLicenseNumber,
    establishmentDate,
    issuanceDate,
    expiryDate,
    legalForm,
    tradeNameEnglish,
    tradeNameArabic,
    isExpired,
    isExpiringSoon,
    document,
    createdAt,
    updatedAt,
  ];
}
