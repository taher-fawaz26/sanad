import 'package:document_flow/document_flow.dart';

/// Builds the flagged [ExtractedDocuments] for a **document-domain
/// rejection** at confirm time (`PUT .../emirates-id` or
/// `PUT .../trade-license`): a 400 whose `code` is `EXTRACTION_INCOMPLETE`,
/// `EXTRACTION_EXPIRED`, or `EXTRACTION_ID_MISMATCH`.
///
/// Unlike registration's `ExtractionResponse.fromDomainRejection`, renewal
/// never needs to attribute a rejection to one of several documents — each
/// renewal flow already concerns exactly one [DocumentType] (the scope), so
/// this is a direct, single-section rebuild rather than a token-matching
/// resolver.
abstract final class LegalDataSubmitRejection {
  LegalDataSubmitRejection._();

  /// Rebuilds [type]'s section from [previous] (so already-extracted field
  /// values keep showing) with the rejection's issue/detail/missingFields
  /// applied instead. [previous] is null when confirm somehow failed before
  /// any extraction populated a section for this scope — an edge case with
  /// nothing to preserve, so the rebuilt section just carries the rejection.
  static ExtractedDocuments flag({
    required DocumentType type,
    required ExtractedDocument? previous,
    required List<String> fields,
    required String message,
    String? code,
  }) => ExtractedDocuments(
    sections: [
      ExtractedDocument(
        type: type,
        fields: previous?.fields ?? const [],
        raw: previous?.raw ?? const {},
        media: previous?.media ?? const [],
        status: previous?.status,
        idVerification: previous?.idVerification,
        issue: _issueForCode(code),
        issueDetail: message.isEmpty ? null : message,
        repair: _repairFor(type, code),
        missingFields: fields,
      ),
    ],
  );

  static DocumentIssue _issueForCode(String? code) => switch (code) {
    'EXTRACTION_ID_MISMATCH' => DocumentIssue.idMismatch,
    _ => DocumentIssue.imageUnclear,
  };

  static DocumentRepairTarget? _repairFor(DocumentType type, String? code) {
    if (code != 'EXTRACTION_ID_MISMATCH') return null;
    if (type != DocumentType.emiratesIdFront) return null;
    return emiratesIdMismatchRepairTarget;
  }
}
