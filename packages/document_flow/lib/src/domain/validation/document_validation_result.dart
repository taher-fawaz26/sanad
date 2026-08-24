import 'package:equatable/equatable.dart';

/// Why a pre-upload document-type check did not pass.
///
/// - [invalidType]: the check ran successfully and determined the captured
///   file is **not** the requested document type (e.g. a person photo where
///   an Emirates ID was requested). The user should retry with the correct
///   document — this is `INVALID_DOCUMENT_TYPE`.
/// - [engineError]: the check itself could not run/complete (scanner/OCR
///   threw, unreadable file, …). This is `VALIDATION_ENGINE_ERROR` — show the
///   existing generic error UX, not a document-specific message.
enum DocumentValidationFailureKind { invalidType, engineError }

/// Outcome of a `DocumentTypeValidator` check.
///
/// This is a **pre-upload gate only** — it answers "is this the requested
/// document type?", never expiry/authenticity/ownership/legal validity (those
/// remain server-side, post-upload responsibilities).
sealed class DocumentValidationResult extends Equatable {
  const DocumentValidationResult();

  const factory DocumentValidationResult.valid() = DocumentValidationValid;

  const factory DocumentValidationResult.invalid() =
      DocumentValidationInvalid;

  const factory DocumentValidationResult.error() = DocumentValidationError;

  @override
  List<Object?> get props => [];
}

/// The captured file looks like the requested document type — proceed with
/// the existing upload/extraction flow unchanged.
final class DocumentValidationValid extends DocumentValidationResult {
  const DocumentValidationValid();
}

/// The captured file does not look like the requested document type.
final class DocumentValidationInvalid extends DocumentValidationResult {
  const DocumentValidationInvalid();
}

/// The validation engine itself failed to run (scanner/OCR error, unreadable
/// file, …) — distinct from a confident "wrong document type" verdict.
final class DocumentValidationError extends DocumentValidationResult {
  const DocumentValidationError();
}
