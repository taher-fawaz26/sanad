import 'package:organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:organization_settings/src/domain/entities/trade_license_legal_data_extraction_entity.dart';

/// Mirrors `TradeLicenseExtractionDto` exactly — the freshly-extracted (not
/// yet persisted) trade licence read inside `LegalDataExtractionResponseDto`.
///
/// Unlike [TradeLicenseResponse] (the persisted-record shape), this has no
/// `id`/`createdAt`/`updatedAt`/document, and it has a required
/// `missingFields` array that the persisted record never carries.
class TradeLicenseExtractionResponse {
  const TradeLicenseExtractionResponse({
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

  factory TradeLicenseExtractionResponse.fromJson(Map<String, dynamic> json) {
    return TradeLicenseExtractionResponse(
      licenseType: json['licenseType'] as String?,
      licenseCategory: json['licenseCategory'] as String?,
      licenseNumber: json['licenseNumber'] as String?,
      unifiedRegistrationNumber: json['unifiedRegistrationNumber'] as String?,
      unifiedLicenseNumber: json['unifiedLicenseNumber'] as String?,
      establishmentDate: json['establishmentDate'] as String?,
      issuanceDate: json['issuanceDate'] as String?,
      expiryDate: json['expiryDate'] as String?,
      legalForm: json['legalForm'] as String?,
      tradeNameEnglish: json['tradeNameEnglish'] as String?,
      tradeNameArabic: json['tradeNameArabic'] as String?,
      status: LegalDataStatus.fromJson(json['status'] as String),
      missingFields: (json['missingFields'] as List<dynamic>).cast<String>(),
    );
  }

  final String? licenseType;
  final String? licenseCategory;
  final String? licenseNumber;
  final String? unifiedRegistrationNumber;
  final String? unifiedLicenseNumber;
  final String? establishmentDate;
  final String? issuanceDate;
  final String? expiryDate;
  final String? legalForm;
  final String? tradeNameEnglish;
  final String? tradeNameArabic;
  final LegalDataStatus status;
  final List<String> missingFields;

  TradeLicenseLegalDataExtractionEntity toEntity() =>
      TradeLicenseLegalDataExtractionEntity(
        licenseType: licenseType,
        licenseCategory: licenseCategory,
        licenseNumber: licenseNumber,
        unifiedRegistrationNumber: unifiedRegistrationNumber,
        unifiedLicenseNumber: unifiedLicenseNumber,
        establishmentDate: establishmentDate,
        issuanceDate: issuanceDate,
        expiryDate: expiryDate,
        legalForm: legalForm,
        tradeNameEnglish: tradeNameEnglish,
        tradeNameArabic: tradeNameArabic,
        status: status,
        missingFields: missingFields,
      );
}
