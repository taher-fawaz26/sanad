/// Client-side, pre-upload document-type validation gate.
///
/// Answers exactly one question — "is this the requested document type?" —
/// for the two flows the product currently gates: Emirates ID (scanner
/// object-detection + text recognition) and Trade License (on-device OCR +
/// a deterministic multi-signal policy). It is never a legal-validity,
/// expiry, authenticity, or ownership check; the backend remains
/// authoritative after upload.
///
/// This is the only package that imports `eid_scanner` and
/// `flutter_tesseract_ocr` — `document_flow` and every feature depend only
/// on `document_flow`'s `DocumentTypeValidator` abstraction, wired here.
library;

// DI. `DocumentValidationDI.init()` registers a `DocumentTypeValidator`
// (from `document_flow`) into the locator — that abstraction, not this
// package's implementation, is the public contract consumers wire against.
export 'src/di/document_validation_di.dart';
// Domain — the OCR/text-recognition scoring policies (exposed for direct
// testing and for any feature that wants to reason about the rule sets
// themselves).
export 'src/domain/policies/emirates_id_signal_policy.dart';
export 'src/domain/policies/trade_license_signal_policy.dart';
