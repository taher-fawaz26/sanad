import 'package:organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:organization_settings/src/domain/entities/personal_legal_data_extraction_entity.dart';

/// Mirrors `NationalIdExtractionDto` exactly — the freshly-extracted (not yet
/// persisted) Emirates ID read inside `LegalDataExtractionResponseDto`.
///
/// Unlike [NationalIdResponse] (the persisted-record shape), this has no
/// `id`/`createdAt`/`updatedAt`/media, and it has a required
/// `missingFields` array that the persisted record never carries.
class NationalIdExtractionResponse {
  const NationalIdExtractionResponse({
    required this.status,
    required this.missingFields,
    this.fullNameEnglish,
    this.fullNameArabic,
    this.idNumber,
    this.nationality,
    this.dateOfBirth,
    this.expiryDate,
    this.gender,
  });

  factory NationalIdExtractionResponse.fromJson(Map<String, dynamic> json) {
    return NationalIdExtractionResponse(
      fullNameEnglish: json['fullNameEnglish'] as String?,
      fullNameArabic: json['fullNameArabic'] as String?,
      idNumber: json['idNumber'] as String?,
      nationality: json['nationality'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      expiryDate: json['expiryDate'] as String?,
      gender: json['gender'] as String?,
      status: LegalDataStatus.fromJson(json['status'] as String),
      missingFields: (json['missingFields'] as List<dynamic>).cast<String>(),
    );
  }

  final String? fullNameEnglish;
  final String? fullNameArabic;
  final String? idNumber;
  final String? nationality;
  final String? dateOfBirth;
  final String? expiryDate;
  final String? gender;
  final LegalDataStatus status;
  final List<String> missingFields;

  PersonalLegalDataExtractionEntity toEntity() =>
      PersonalLegalDataExtractionEntity(
        fullNameEnglish: fullNameEnglish,
        fullNameArabic: fullNameArabic,
        idNumber: idNumber,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        expiryDate: expiryDate,
        gender: gender,
        status: status,
        missingFields: missingFields,
      );
}
