import 'package:core/core.dart' show Failure;
import 'package:document_flow/document_flow.dart' show DocumentFlowRepository;
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart'
    show DocumentFlowRepository;
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
  const SubmitFailure({required super.messageKey});
}
