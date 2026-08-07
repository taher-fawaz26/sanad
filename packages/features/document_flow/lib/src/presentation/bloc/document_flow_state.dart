part of 'document_flow_bloc.dart';

/// Sealed async-phase state machine, matching the flow's overall stage.
///
/// Per-slot upload lifecycle (uploading/uploaded/failed + progress) is
/// carried separately, per [DocumentType], via [UploadableAsset] — that lets
/// several documents upload concurrently with independent progress instead
/// of collapsing into one global "uploading" phase.
sealed class DocumentFlowPhase extends Equatable {
  const DocumentFlowPhase();

  @override
  List<Object?> get props => [];
}

final class PhaseIdle extends DocumentFlowPhase {
  const PhaseIdle();
}

final class PhaseExtracting extends DocumentFlowPhase {
  const PhaseExtracting();
}

final class PhaseExtracted extends DocumentFlowPhase {
  const PhaseExtracted();
}

/// The user is reviewing/editing extracted fields before submit.
final class PhaseEditing extends DocumentFlowPhase {
  const PhaseEditing();
}

final class PhaseSubmitting extends DocumentFlowPhase {
  const PhaseSubmitting();
}

final class PhaseSuccess extends DocumentFlowPhase {
  const PhaseSuccess();
}

/// Which stage failed, so [RetryRequested] knows what to re-attempt.
enum FailedStage { extraction, submit }

final class PhaseFailure extends DocumentFlowPhase {
  const PhaseFailure(this.stage);

  final FailedStage stage;

  @override
  List<Object?> get props => [stage];
}

/// Immutable state carried for the lifetime of a document flow instance.
class DocumentFlowState extends Equatable {
  const DocumentFlowState({
    required this.config,
    this.context = const DocumentFlowContext(),
    this.documents = const {},
    this.phase = const PhaseIdle(),
    this.extracted,
    this.failure,
  });

  final DocumentFlowConfig config;
  final DocumentFlowContext context;

  /// Captured/uploaded documents keyed by slot.
  final Map<DocumentType, UploadableAsset> documents;

  final DocumentFlowPhase phase;
  final ExtractedDocuments? extracted;
  final DocumentFlowFailure? failure;

  UploadableAsset? documentAt(DocumentType type) => documents[type];

  /// Backend ids for every uploaded document, suitable for
  /// [ExtractParams]/[SubmitParams].
  Map<DocumentType, String> get uploadedIds => {
    for (final entry in documents.entries)
      if (entry.value.remoteId != null) entry.key: entry.value.remoteId!,
  };

  /// True once every document [DocumentFlowConfig.requiredDocuments] lists
  /// has been uploaded successfully.
  bool get isComplete => DocumentValidation.isComplete(config, uploadedIds);

  DocumentFlowState copyWith({
    DocumentFlowContext? context,
    Map<DocumentType, UploadableAsset>? documents,
    DocumentFlowPhase? phase,
    Object? extracted = _sentinel,
    Object? failure = _sentinel,
  }) => DocumentFlowState(
    config: config,
    context: context ?? this.context,
    documents: documents ?? this.documents,
    phase: phase ?? this.phase,
    extracted: identical(extracted, _sentinel)
        ? this.extracted
        : extracted as ExtractedDocuments?,
    failure: identical(failure, _sentinel)
        ? this.failure
        : failure as DocumentFlowFailure?,
  );

  static const Object _sentinel = Object();

  @override
  List<Object?> get props => [
    config,
    context,
    documents,
    phase,
    extracted,
    failure,
  ];
}
