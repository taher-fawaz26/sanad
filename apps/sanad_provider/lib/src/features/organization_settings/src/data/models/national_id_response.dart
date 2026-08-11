import 'package:sanad_provider/src/features/organization_settings/src/data/models/legal_data_media_response.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/personal_legal_data_entity.dart';

/// Mirrors `NationalIdResponseDto` exactly.
class NationalIdResponse {
  const NationalIdResponse({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.fullNameEnglish,
    this.fullNameArabic,
    this.idNumber,
    this.nationality,
    this.dateOfBirth,
    this.expiryDate,
    this.gender,
    this.frontMedia,
    this.backMedia,
  });

  factory NationalIdResponse.fromJson(Map<String, dynamic> json) {
    final front = json['frontMedia'] as Map<String, dynamic>?;
    final back = json['backMedia'] as Map<String, dynamic>?;

    return NationalIdResponse(
      id: json['id'] as String,
      fullNameEnglish: json['fullNameEnglish'] as String?,
      fullNameArabic: json['fullNameArabic'] as String?,
      idNumber: json['idNumber'] as String?,
      nationality: json['nationality'] as String?,
      dateOfBirth: json['dateOfBirth'] as String?,
      expiryDate: json['expiryDate'] as String?,
      gender: json['gender'] as String?,
      status: LegalDataStatus.fromJson(json['status'] as String),
      frontMedia: front == null ? null : LegalDataMediaResponse.fromJson(front),
      backMedia: back == null ? null : LegalDataMediaResponse.fromJson(back),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  final String id;
  final String? fullNameEnglish;
  final String? fullNameArabic;
  final String? idNumber;
  final String? nationality;
  final String? dateOfBirth;
  final String? expiryDate;
  final String? gender;
  final LegalDataStatus status;
  final LegalDataMediaResponse? frontMedia;
  final LegalDataMediaResponse? backMedia;
  final DateTime createdAt;
  final DateTime updatedAt;

  PersonalLegalDataEntity toEntity() => PersonalLegalDataEntity(
    id: id,
    fullNameEnglish: fullNameEnglish,
    fullNameArabic: fullNameArabic,
    idNumber: idNumber,
    nationality: nationality,
    dateOfBirth: dateOfBirth,
    expiryDate: expiryDate,
    gender: gender,
    status: status,
    frontMedia: frontMedia?.toEntity(),
    backMedia: backMedia?.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
