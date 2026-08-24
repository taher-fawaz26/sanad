import 'package:document_flow/document_flow.dart' show IdVerification;
import 'package:equatable/equatable.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/legal_data_status.dart';

/// A freshly-extracted (not yet persisted) Emirates ID read — returned bare
/// by `POST service-provider/legal-data/emirates-id/extract`
/// (`NationalIdExtractionDto`).
///
/// Deliberately distinct from [PersonalLegalDataEntity]: this is a
/// preview/extraction result, not a saved record, so it carries no
/// `id`/`createdAt`/`updatedAt`/media — and it adds [missingFields] and
/// [idVerification], which the persisted record never has.
class PersonalLegalDataExtractionEntity extends Equatable {
  const PersonalLegalDataExtractionEntity({
    required this.status,
    required this.missingFields,
    this.fullNameEnglish,
    this.fullNameArabic,
    this.idNumber,
    this.nationality,
    this.dateOfBirth,
    this.expiryDate,
    this.gender,
    this.idVerification,
  });

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
  final LegalDataStatus status;

  /// Fields the AI could not read (upstream snake_case names, e.g.
  /// `id_number`). Not persisted.
  final List<String> missingFields;

  /// The extractor's front/back comparison. Not persisted.
  final IdVerification? idVerification;

  @override
  List<Object?> get props => [
    fullNameEnglish,
    fullNameArabic,
    idNumber,
    nationality,
    dateOfBirth,
    expiryDate,
    gender,
    status,
    missingFields,
    idVerification,
  ];
}
