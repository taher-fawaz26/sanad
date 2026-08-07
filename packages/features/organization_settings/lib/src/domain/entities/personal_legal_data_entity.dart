import 'package:equatable/equatable.dart';
import 'package:organization_settings/src/domain/entities/media_entity.dart';

/// The organization owner's Emirates ID data, extracted by the backend from
/// the uploaded document — `NationalIdResponseDto`.
class PersonalLegalDataEntity extends Equatable {
  const PersonalLegalDataEntity({
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

  final String id;
  final String? fullNameEnglish;
  final String? fullNameArabic;
  final String? idNumber;
  final String? nationality;

  /// ISO date string (e.g. `1990-01-15`).
  final String? dateOfBirth;

  /// ISO date string (e.g. `2028-05-20`).
  final String? expiryDate;

  /// `male` / `female`, as returned by the backend.
  final String? gender;
  final bool isExpired;
  final bool isExpiringSoon;
  final MediaEntity? frontMedia;
  final MediaEntity? backMedia;
  final DateTime createdAt;
  final DateTime updatedAt;

  @override
  List<Object?> get props => [
    id,
    fullNameEnglish,
    fullNameArabic,
    idNumber,
    nationality,
    dateOfBirth,
    expiryDate,
    gender,
    isExpired,
    isExpiringSoon,
    frontMedia,
    backMedia,
    createdAt,
    updatedAt,
  ];
}
