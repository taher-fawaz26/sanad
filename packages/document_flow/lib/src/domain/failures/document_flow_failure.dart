import 'package:core/core.dart' show Failure;
import 'package:document_flow/document_flow.dart' show DocumentFlowRepository;
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart'
    show DocumentFlowRepository;
import 'package:document_flow/src/domain/validation/document_validation_result.dart'
    show DocumentValidationFailureKind;
import 'package:equatable/equatable.dart';

/// Why an extraction call failed, distinct from a plain network/server error.
///
/// - [network]: transport failure (no internet, timeout, cancelled, secure
///   connection) — show connectivity UI.
/// - [server]: 5xx / unclassified server error — show a generic "try again".
/// - [domain]: the backend intentionally rejected the request with a
///   user-facing message (business rule, validation, conflict) — show that
///   message, not a connectivity error.
enum ExtractionFailureKind { missingContext, network, server, domain }

/// Typed failures for the upload → extract → submit pipeline.
///
/// Feature packages may still receive plain [Failure]s (e.g. from
/// [DocumentFlowRepository]); these wrap them with flow-stage context so the
/// UI can react differently to an upload failure vs a submit failure.
sealed class DocumentFlowFailure extends Equatable {
  const DocumentFlowFailure({required this.messageKey});

  final String messageKey;

  @override
  List<Object?> get props => [messageKey];
}

final class UploadFailure extends DocumentFlowFailure {
  const UploadFailure({required super.messageKey});
}

final class ExtractionFailure extends DocumentFlowFailure {
  const ExtractionFailure({
    required super.messageKey,
    required this.kind,
    this.code,
    this.fields = const [],
    this.requestId,
  });

  final ExtractionFailureKind kind;

  /// Backend error code (e.g. `EXTRACTION_INCOMPLETE`), when the failure
  /// originated from a structured backend response.
  final String? code;

  /// Backend-identified fields the extraction could not read (e.g.
  /// `license_number`), when provided.
  final List<String> fields;

  /// Backend request id for support/correlation, when provided.
  final String? requestId;

  @override
  List<Object?> get props => [messageKey, kind, code, fields, requestId];
}

final class SubmitFailure extends DocumentFlowFailure {
  const SubmitFailure({
    required super.messageKey,
    this.code,
    this.fields = const [],
    this.requestId,
  });

  /// Backend error code (e.g. `EXTRACTION_INCOMPLETE`), when the failure
  /// originated from a structured backend response. Callers should switch on
  /// this, never on [messageKey] (which may be raw backend prose).
  final String? code;

  /// Backend-identified fields the confirmation could not verify (e.g.
  /// `license_number`), when provided.
  final List<String> fields;

  /// Backend request id for support/correlation, when provided.
  final String? requestId;

  @override
  List<Object?> get props => [messageKey, code, fields, requestId];
}

/// A pre-upload document-type check (see `DocumentTypeValidator`) did not
/// pass.
///
/// Distinguishes a confident "wrong document type" verdict
/// (`DocumentValidationFailureKind.invalidType`) from the check itself
/// failing to run (`DocumentValidationFailureKind.engineError`) — the UI
/// shows a document-specific retry message for the former and the existing
/// generic error UX for the latter. No upload happens in either case.
///
/// Named `DocumentValidationFailure`, not `ValidationFailure`, to avoid
/// colliding with `core`'s own `ValidationFailure` (a plain-request-field
/// validation error, unrelated to this pre-upload document-type gate) —
/// `document_flow` already re-exports `core`'s hierarchy via
/// [DocumentFlowFailure]'s own consumers importing both barrels.
final class DocumentValidationFailure extends DocumentFlowFailure {
  const DocumentValidationFailure({
    required super.messageKey,
    required this.kind,
  });

  final DocumentValidationFailureKind kind;

  @override
  List<Object?> get props => [messageKey, kind];
}
