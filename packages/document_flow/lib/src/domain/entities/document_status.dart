import 'package:document_flow/src/domain/entities/extracted_field.dart'
    show DocumentIssue;

/// A document's server-derived lifecycle status, recomputed from its expiry
/// date on every read. Distinct from [DocumentIssue]: a status of
/// [DocumentStatus.expiringSoon] is a non-blocking warning, not a reason to
/// refuse submit.
enum DocumentStatus {
  verified,
  expiringSoon,
  expired
  ;

  /// Parses the backend's snake_case wire value. Defaults to [verified] for
  /// an unrecognized value rather than throwing, since a document status is
  /// advisory (badge/warning), never a gate on its own.
  static DocumentStatus fromWire(String? value) => switch (value) {
    'expiring_soon' => DocumentStatus.expiringSoon,
    'expired' => DocumentStatus.expired,
    _ => DocumentStatus.verified,
  };
}
