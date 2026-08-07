/// Backend endpoints for the organization legal-documents update flow.
abstract final class LegalDataApiPaths {
  LegalDataApiPaths._();

  /// `GET` — current legal data (`personalLegalData` +
  /// `tradeLicenseLegalData`).
  static const String legalData = 'service-provider/legal-data';

  /// `POST` — extract OCR data from previously uploaded document media ids.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId, tradeLicenseId }`.
  static const String extract = 'service-provider/legal-data/extract';

  /// `PUT` — persist the (possibly re-uploaded) document media ids.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId, tradeLicenseId }`.
  static const String documents = 'service-provider/legal-data/documents';
}
