import 'package:document_flow/document_flow.dart';

/// Which legal document the update flow is scoped to.
///
/// A compliance card only ever concerns the user with *its own* document —
/// tapping "Renew"/"Replace" on the Emirates ID card must not surface the
/// Trade Licence, and vice versa. This scope is threaded from the card's CTA
/// through the route into [LegalDocumentsPage] so exactly one document's
/// slots are shown, regardless of what else happens to be on file.
enum DocumentScope {
  emiratesId,
  tradeLicense
  ;

  /// Slots required to consider *this scope* complete.
  ///
  /// Deliberately excludes the other document: an individual provider has no
  /// trade licence, so the Emirates ID scope must never require one, and a
  /// trade-licence renewal must never block on Emirates ID slots the user
  /// isn't touching.
  List<DocumentType> get requiredDocuments => switch (this) {
    DocumentScope.emiratesId => const [
      DocumentType.emiratesIdFront,
      DocumentType.emiratesIdBack,
    ],
    DocumentScope.tradeLicense => const [DocumentType.tradeLicense],
  };

  String get titleKey => switch (this) {
    DocumentScope.emiratesId => 'settings.legal_documents.emirates_id',
    DocumentScope.tradeLicense => 'settings.legal_documents.trade_license',
  };
}
