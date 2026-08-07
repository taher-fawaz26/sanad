import 'package:organization_settings/src/data/models/legal_data_media_response.dart';
import 'package:organization_settings/src/domain/entities/personal_legal_data_entity.dart';

/// Mirrors `NationalIdResponseDto` exactly.
class NationalIdResponse {
  const NationalIdResponse({
    required this.id,
    required this.isExpired,
    required this.isExpiringSoon,
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
      isExpired: json['isExpired'] as bool,
      isExpiringSoon: json['isExpiringSoon'] as bool,
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
  final bool isExpired;
  final bool isExpiringSoon;
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
    isExpired: isExpired,
    isExpiringSoon: isExpiringSoon,
    frontMedia: frontMedia?.toEntity(),
    backMedia: backMedia?.toEntity(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
