import 'package:equatable/equatable.dart';
import 'package:organization_settings/src/domain/entities/legal_data_status.dart';

/// A freshly-extracted (not yet persisted) trade licence read — returned by
/// `POST service-provider/legal-data/extract` (`TradeLicenseExtractionDto`).
///
/// Deliberately distinct from [TradeLicenseLegalDataEntity]: this is a
/// preview/extraction result, not a saved record, so it carries no
/// `id`/`createdAt`/`updatedAt`/document — and it adds [missingFields], which
/// the persisted record never has.
class TradeLicenseLegalDataExtractionEntity extends Equatable {
  const TradeLicenseLegalDataExtractionEntity({
    required this.status,
    required this.missingFields,
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
  });

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
  final LegalDataStatus status;

  /// Fields the AI could not read (upstream snake_case names, e.g.
  /// `license_number`). Not persisted.
  final List<String> missingFields;

  @override
  List<Object?> get props => [
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
    status,
    missingFields,
  ];
}
