import 'package:asset_picker/asset_picker.dart';
import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/domain/validation/document_validation_result.dart';

/// Client-side, pre-upload gate: "is this the requested document type?"
///
/// Implementations own whatever local capability answers that question for a
/// given [DocumentType] (a bundled scanner SDK, on-device OCR, …) — this
/// package never depends on those SDKs directly. A feature wires a concrete
/// implementation in via DI; `DocumentFlowBloc` runs it before the existing
/// upload/extraction pipeline and never sees the underlying technology.
///
/// This is **not** a legal-validity check: expiry, authenticity, ownership,
/// and correctness remain the backend's responsibility after upload.
// A deliberate single-method strategy interface (DI-swappable, mockable in
// tests) — not a case of over-abstraction.
// ignore: one_member_abstracts
abstract interface class DocumentTypeValidator {
  /// Validates that [asset] looks like [type].
  ///
  /// Must not throw for a malformed/unreadable file — return
  /// [DocumentValidationResult.error] instead so the caller can distinguish
  /// an engine failure from a confident rejection.
  Future<DocumentValidationResult> validate(
    PickedAsset asset, {
    required DocumentType type,
  });
}
