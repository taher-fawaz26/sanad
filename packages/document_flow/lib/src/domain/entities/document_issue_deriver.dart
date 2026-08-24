import 'package:document_flow/src/domain/entities/document_status.dart';
import 'package:document_flow/src/domain/entities/extracted_field.dart';
import 'package:document_flow/src/domain/entities/id_verification.dart';

/// Derives the blocking [DocumentIssue] from a preview's explicit signals.
///
/// Shared by every feature that parses an extraction preview (onboarding,
/// renewal) so the two derive identically. [status] is checked first —
/// [DocumentStatus.expired] always blocks; [DocumentStatus.expiringSoon] is a
/// non-blocking warning and falls through to the remaining checks. Pass
/// [idVerification] only for a document that has the concept (Emirates ID);
/// omit it for a trade licence.
DocumentIssue deriveDocumentIssue({
  required DocumentStatus status,
  required List<String> missingFields,
  IdVerification? idVerification,
}) {
  if (status == DocumentStatus.expired) return DocumentIssue.expired;
  if (missingFields.isNotEmpty) return DocumentIssue.imageUnclear;
  if (idVerification != null && !idVerification.matched) {
    return DocumentIssue.idMismatch;
  }
  return DocumentIssue.none;
}
