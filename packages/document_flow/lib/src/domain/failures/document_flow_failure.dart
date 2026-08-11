import 'package:core/core.dart' show Failure;
import 'package:document_flow/document_flow.dart' show DocumentFlowRepository;
import 'package:document_flow/src/domain/repositories/document_flow_repository.dart' show DocumentFlowRepository;
import 'package:equatable/equatable.dart';

/// Why an extraction call failed, distinct from a plain network/server error.
enum ExtractionFailureKind { missingContext, network, server }

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
  });

  final ExtractionFailureKind kind;

  @override
  List<Object?> get props => [messageKey, kind];
}

final class SubmitFailure extends DocumentFlowFailure {
  const SubmitFailure({required super.messageKey});
}
