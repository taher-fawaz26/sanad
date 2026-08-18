import 'package:asset_picker/asset_picker.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:document_flow/src/domain/entities/document_flow_config.dart';
import 'package:document_flow/src/domain/entities/document_flow_context.dart';
import 'package:document_flow/src/domain/entities/document_type.dart';
import 'package:document_flow/src/domain/entities/document_validation.dart';
import 'package:document_flow/src/domain/entities/extracted_document.dart';
import 'package:document_flow/src/domain/entities/extracted_field.dart';
import 'package:document_flow/src/domain/failures/document_flow_failure.dart'
    as flow_failure;
import 'package:document_flow/src/domain/failures/document_flow_failure.dart'
    show DocumentFlowFailure;
import 'package:document_flow/src/domain/usecases/document_flow_params.dart';
import 'package:document_flow/src/domain/usecases/extract_documents_usecase.dart';
import 'package:document_flow/src/domain/usecases/fetch_documents_usecase.dart';
import 'package:document_flow/src/domain/usecases/submit_documents_usecase.dart';
import 'package:document_flow/src/domain/usecases/upload_media_usecase.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'document_flow_event.dart';
part 'document_flow_state.dart';

/// The single reusable state machine for upload → extract → review → submit.
///
/// One instance is created per flow (per feature usage), bound to that
/// feature's `DocumentFlowRepository` implementation via the injected use
/// cases. Networking, endpoints, and success handling are entirely owned by
/// those use cases — this class only orchestrates transitions.
class DocumentFlowBloc extends Bloc<DocumentFlowEvent, DocumentFlowState> {
  DocumentFlowBloc({
    required DocumentFlowConfig config,
    required UploadMediaUseCase uploadMedia,
    required ExtractDocumentsUseCase extractDocuments,
    required SubmitDocumentsUseCase submitDocuments,
    required FetchDocumentsUseCase fetchDocuments,
  }) : _uploadMedia = uploadMedia,
       _extractDocuments = extractDocuments,
       _submitDocuments = submitDocuments,
       _fetchDocuments = fetchDocuments,
       super(DocumentFlowState(config: config)) {
    on<DocumentFlowStarted>(_onStarted);
    on<DocumentPicked>(_onPicked);
    // Intentionally NOT droppable: uploads are keyed per DocumentType and
    // legitimately run concurrently (Emirates ID + trade license at once) —
    // droppable() operates per event type, so it would drop a second
    // document's upload while the first is still in flight.
    on<DocumentUploadRequested>(_onUploadRequested);
    on<DocumentUploadCancelled>(_onUploadCancelled);
    on<DocumentRemoved>(_onRemoved);
    // Single flow-wide operation (not per-type) — safe to drop duplicates.
    on<ExtractionRequested>(_onExtractionRequested, transformer: droppable());
    on<EditingStarted>(_onEditingStarted);
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<SubmitRequested>(_onSubmitRequested, transformer: droppable());
    on<FlowReset>(_onReset);
    on<RetryRequested>(_onRetry);
  }

  final UploadMediaUseCase _uploadMedia;
  final ExtractDocumentsUseCase _extractDocuments;
  final SubmitDocumentsUseCase _submitDocuments;
  final FetchDocumentsUseCase _fetchDocuments;

  Future<void> _onStarted(
    DocumentFlowStarted event,
    Emitter<DocumentFlowState> emit,
  ) async {
    emit(state.copyWith(context: event.context));

    if (!state.config.enablePrefetch) return;

    final result = await _fetchDocuments(
      FetchParams(context: event.context),
    ).run();
    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          phase: const PhaseFailure(FailedStage.extraction),
          failure: _toExtractionFailure(failure),
        ),
      ),
      (extracted) => emit(
        state.copyWith(
          documents: _withPrefilledDocuments(extracted),
          extracted: extracted,
          phase: const PhaseExtracted(),
        ),
      ),
    );
  }

  /// Maps a repository [Failure] to a flow `ExtractionFailure`, classifying
  /// it as `network` (genuine transport failure — show connectivity UI),
  /// `server` (5xx/unclassified — generic error), or `domain` (the backend
  /// intentionally rejected the request with a user-facing message — show
  /// that message, not a connectivity error). The backend `code`/`fields`/
  /// `requestId` are preserved from `Failure.metadata` rather than dropped.
  flow_failure.ExtractionFailure _toExtractionFailure(Failure failure) {
    final kind = switch (failure) {
      NoInternetFailure() ||
      TimeoutFailure() ||
      NetworkFailure() ||
      SecureConnectionFailure() => flow_failure.ExtractionFailureKind.network,
      ServerFailure() ||
      UnknownFailure() => flow_failure.ExtractionFailureKind.server,
      _ => flow_failure.ExtractionFailureKind.domain,
    };
    final metadata = failure.metadata;
    return flow_failure.ExtractionFailure(
      messageKey: failure.message,
      kind: kind,
      code: metadata?['code']?.toString() ?? failure.code,
      fields:
          (metadata?['fields'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      requestId: metadata?['requestId']?.toString(),
    );
  }

  /// Seeds already-uploaded slots from a fetch prefill's [DocumentMediaRef]s,
  /// so `state.uploadedIds`/`isComplete` see them without a re-upload.
  Map<DocumentType, UploadableAsset> _withPrefilledDocuments(
    ExtractedDocuments extracted,
  ) {
    final documents = {...state.documents};
    for (final section in extracted.sections) {
      for (final ref in section.media) {
        if (documents.containsKey(ref.type)) continue;
        final placeholder = PickedAsset(
          name: ref.fileName ?? ref.mediaId,
          path: '',
          mimeType: ref.mimeType ?? 'application/octet-stream',
          size: 0,
          assetType: AssetType.image,
        );
        documents[ref.type] = placeholder.toUploadable().markUploaded(
          remoteId: ref.mediaId,
          remoteUrl: ref.mediaUrl,
        );
      }
    }
    return documents;
  }

  void _onPicked(DocumentPicked event, Emitter<DocumentFlowState> emit) {
    emit(
      _withDocument(event.type, event.asset.toUploadable()).copyWith(
        failure: null,
      ),
    );
  }

  Future<void> _onUploadRequested(
    DocumentUploadRequested event,
    Emitter<DocumentFlowState> emit,
  ) async {
    final current = state.documentAt(event.type);
    if (current == null) return;

    emit(
      _withDocument(event.type, current.markUploading()).copyWith(
        failure: null,
      ),
    );

    final result = await _uploadMedia(
      UploadMediaParams(
        type: event.type,
        filePath: current.asset.path,
        fileName: current.asset.name,
        mimeType: current.asset.mimeType,
        uploadKey: event.type.name,
        context: state.context,
        onProgress: (progress) {
          final inFlight = state.documentAt(event.type);
          if (inFlight == null || !inFlight.isUploading) return;
          emit(_withDocument(event.type, inFlight.markUploading(progress)));
        },
      ),
    ).run();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (failure is NetworkFailure &&
            failure.message == 'errors.request_cancelled') {
          emit(_withDocument(event.type, null));
          return;
        }
        final inFlight = state.documentAt(event.type);
        final failed = (inFlight ?? current).markFailed(failure.message);
        emit(
          _withDocument(event.type, failed).copyWith(
            failure: flow_failure.UploadFailure(messageKey: failure.message),
          ),
        );
      },
      (media) {
        final inFlight = state.documentAt(event.type);
        if (inFlight == null) return;
        emit(
          _withDocument(
            event.type,
            inFlight.markUploaded(remoteId: media.id, remoteUrl: media.url),
          ),
        );
      },
    );
  }

  void _onUploadCancelled(
    DocumentUploadCancelled event,
    Emitter<DocumentFlowState> emit,
  ) {
    _uploadMedia.cancel(event.type.name);
  }

  void _onRemoved(DocumentRemoved event, Emitter<DocumentFlowState> emit) {
    _uploadMedia.cancel(event.type.name);
    emit(_withDocument(event.type, null));
  }

  Future<void> _onExtractionRequested(
    ExtractionRequested event,
    Emitter<DocumentFlowState> emit,
  ) async {
    if (state.config.enableValidation &&
        !DocumentValidation.isComplete(state.config, state.uploadedIds)) {
      emit(
        state.copyWith(
          phase: const PhaseFailure(FailedStage.extraction),
          failure: const flow_failure.ExtractionFailure(
            messageKey: 'errors.required_fields_missing',
            kind: flow_failure.ExtractionFailureKind.missingContext,
          ),
        ),
      );
      return;
    }

    if (!state.config.enableExtraction) {
      emit(state.copyWith(phase: const PhaseExtracted()));
      return;
    }

    emit(state.copyWith(phase: const PhaseExtracting(), failure: null));

    final result = await _extractDocuments(
      ExtractParams(uploadedIds: state.uploadedIds, context: state.context),
    ).run();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (failure is ConflictFailure) {
          emit(
            state.copyWith(
              extracted: const ExtractedDocuments(
                sections: [
                  ExtractedDocument(
                    type: DocumentType.emiratesIdFront,
                    fields: [],
                    issue: DocumentIssue.alreadyRegistered,
                  ),
                ],
              ),
              phase: const PhaseExtracted(),
              failure: null,
            ),
          );
        } else {
          emit(
            state.copyWith(
              phase: const PhaseFailure(FailedStage.extraction),
              failure: _toExtractionFailure(failure),
            ),
          );
        }
      },
      (extracted) => emit(
        state.copyWith(
          extracted: extracted,
          phase: const PhaseExtracted(),
          failure: null,
        ),
      ),
    );
  }

  void _onEditingStarted(
    EditingStarted event,
    Emitter<DocumentFlowState> emit,
  ) {
    emit(state.copyWith(phase: const PhaseEditing()));
  }

  Future<void> _onSubmitRequested(
    SubmitRequested event,
    Emitter<DocumentFlowState> emit,
  ) async {
    if (state.config.enableValidation &&
        !DocumentValidation.isComplete(state.config, state.uploadedIds)) {
      emit(
        state.copyWith(
          phase: const PhaseFailure(FailedStage.submit),
          failure: const flow_failure.SubmitFailure(
            messageKey: 'errors.required_fields_missing',
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(phase: const PhaseSubmitting(), failure: null));

    final result = await _submitDocuments(
      SubmitParams(
        uploadedIds: state.uploadedIds,
        extracted: state.extracted,
        context: state.context,
      ),
    ).run();

    if (isClosed) return;

    result.fold(
      (failure) => emit(
        state.copyWith(
          phase: const PhaseFailure(FailedStage.submit),
          failure: flow_failure.SubmitFailure(messageKey: failure.message),
        ),
      ),
      (_) => emit(state.copyWith(phase: const PhaseSuccess())),
    );
  }

  void _onReset(FlowReset event, Emitter<DocumentFlowState> emit) {
    for (final type in state.documents.keys) {
      _uploadMedia.cancel(type.name);
    }
    emit(
      DocumentFlowState(config: state.config, context: state.context),
    );
  }

  Future<void> _onRetry(
    RetryRequested event,
    Emitter<DocumentFlowState> emit,
  ) async {
    final phase = state.phase;
    if (phase is! PhaseFailure) return;
    switch (phase.stage) {
      case FailedStage.extraction:
        await _onExtractionRequested(const ExtractionRequested(), emit);
      case FailedStage.submit:
        await _onSubmitRequested(const SubmitRequested(), emit);
    }
  }

  DocumentFlowState _withDocument(DocumentType type, UploadableAsset? value) {
    final documents = {...state.documents};
    if (value == null) {
      documents.remove(type);
    } else {
      documents[type] = value;
    }
    return state.copyWith(documents: documents);
  }
}
