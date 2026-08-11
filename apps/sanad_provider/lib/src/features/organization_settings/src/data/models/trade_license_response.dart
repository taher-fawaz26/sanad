import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_media_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/trade_license_legal_data_entity.dart';

/// Mirrors `TradeLicenseResponseDto` exactly.
class TradeLicenseResponse {
  const TradeLicenseResponse({
    required this.id,
    required this.status,
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

  factory TradeLicenseResponse.fromJson(Map<String, dynamic> json) {
    final document = json['document'] as Map<String, dynamic>?;

    return TradeLicenseResponse(
      id: json['id'] as String,
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
      document: document == null
          ? null
          : LegalDataMediaResponse.fromJson(document),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
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
  final LegalDataMediaResponse? document;
  final DateTime createdAt;
  final DateTime updatedAt;

  TradeLicenseLegalDataEntity toEntity() => TradeLicenseLegalDataEntity(
    id: id,
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
    document: document?.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
