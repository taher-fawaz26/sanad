part of 'document_flow_bloc.dart';

sealed class DocumentFlowEvent extends Equatable {
  const DocumentFlowEvent();

  @override
  List<Object?> get props => [];
}

/// Seeds runtime context (e.g. an onboarding token) and, when
/// `config.enablePrefetch` is true, triggers an initial fetch.
final class DocumentFlowStarted extends DocumentFlowEvent {
  const DocumentFlowStarted({this.context = const DocumentFlowContext()});

  final DocumentFlowContext context;

  @override
  List<Object?> get props => [context];
}

/// Stores a captured asset for [type] without uploading it yet.
final class DocumentPicked extends DocumentFlowEvent {
  const DocumentPicked({required this.type, required this.asset});

  final DocumentType type;
  final PickedAsset asset;

  @override
  List<Object?> get props => [type, asset];
}

/// Uploads the asset currently captured for [type].
final class DocumentUploadRequested extends DocumentFlowEvent {
  const DocumentUploadRequested(this.type);

  final DocumentType type;

  @override
  List<Object?> get props => [type];
}

final class DocumentUploadCancelled extends DocumentFlowEvent {
  const DocumentUploadCancelled(this.type);

  final DocumentType type;

  @override
  List<Object?> get props => [type];
}

/// Clears [type]'s slot and cancels any in-flight upload for it.
final class DocumentRemoved extends DocumentFlowEvent {
  const DocumentRemoved(this.type);

  final DocumentType type;

  @override
  List<Object?> get props => [type];
}

final class ExtractionRequested extends DocumentFlowEvent {
  const ExtractionRequested();
}

/// Moves from `extracted` into the editable review phase.
final class EditingStarted extends DocumentFlowEvent {
  const EditingStarted();
}

final class SubmitRequested extends DocumentFlowEvent {
  const SubmitRequested();
}

/// Resets the entire flow back to [PhaseIdle] with no documents.
final class FlowReset extends DocumentFlowEvent {
  const FlowReset();
}

/// Re-attempts whatever failed last (extraction or submit).
final class RetryRequested extends DocumentFlowEvent {
  const RetryRequested();
}
