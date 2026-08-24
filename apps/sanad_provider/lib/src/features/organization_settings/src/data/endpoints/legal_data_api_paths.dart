/// Backend endpoints for the organization legal-documents renewal flow.
///
/// Renewal is split per document — there is no combined extract/confirm pair
/// any more. `POST service-provider/legal-data/extract` and
/// `PUT service-provider/legal-data/documents` are removed, not deprecated;
/// do not reintroduce them.
abstract final class LegalDataApiPaths {
  LegalDataApiPaths._();

  /// `GET` — current stored legal data (`personalLegalData` +
  /// `tradeLicenseLegalData`), with per-document `status`.
  static const String legalData = 'service-provider/legal-data';

  /// `POST` — preview a replacement Emirates ID from previously uploaded
  /// document media ids. Response is a bare `NationalIdExtractionDto` — no
  /// outer envelope.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId }`.
  static const String emiratesIdExtract =
      'service-provider/legal-data/emirates-id/extract';

  /// `PUT` — confirm the reviewed Emirates ID extraction. Leaves the trade
  /// licence untouched and resets the profile to pending review.
  ///
  /// Body: `{ emiratesIdFrontId, emiratesIdBackId }`.
  static const String emiratesIdConfirm =
      'service-provider/legal-data/emirates-id';

  /// `POST` — preview a replacement trade licence. Companies only. Response
  /// is a bare `TradeLicenseExtractionDto` — no outer envelope.
  ///
  /// Body: `{ tradeLicenseId }`.
  static const String tradeLicenseExtract =
      'service-provider/legal-data/trade-license/extract';

  /// `PUT` — confirm the reviewed trade licence extraction. Leaves the
  /// Emirates ID untouched and resets the profile to pending review.
  ///
  /// Body: `{ tradeLicenseId }`.
  static const String tradeLicenseConfirm =
      'service-provider/legal-data/trade-license';
}
