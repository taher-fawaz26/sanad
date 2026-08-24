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
import 'package:document_flow/src/domain/validation/document_type_validator.dart';
import 'package:document_flow/src/domain/validation/document_validation_result.dart';
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
    DocumentTypeValidator? validator,
  }) : _uploadMedia = uploadMedia,
       _extractDocuments = extractDocuments,
       _submitDocuments = submitDocuments,
       _fetchDocuments = fetchDocuments,
       _validator = validator,
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
    on<ReviewFlagged>(_onReviewFlagged);
    on<FlowReset>(_onReset);
    on<RetryRequested>(_onRetry);
  }

  final UploadMediaUseCase _uploadMedia;
  final ExtractDocumentsUseCase _extractDocuments;
  final SubmitDocumentsUseCase _submitDocuments;
  final FetchDocumentsUseCase _fetchDocuments;

  /// Pre-upload document-type gate. `null` skips validation entirely — the
  /// legacy contract, where [DocumentPicked] only stores the asset and the
  /// caller must dispatch [DocumentUploadRequested] itself. When set, a
  /// passing check auto-triggers the upload; a failing one reverts the slot
  /// to whatever it held before this pick (never destroying an already
  /// uploaded document) and surfaces a
  /// [flow_failure.DocumentValidationFailure].
  final DocumentTypeValidator? _validator;

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

  Future<void> _onPicked(
    DocumentPicked event,
    Emitter<DocumentFlowState> emit,
  ) async {
    final validator = _validator;
    if (validator == null) {
      // Legacy contract: store only. The caller (e.g.
      // `DocumentFlowController.pick`) is responsible for dispatching
      // `DocumentUploadRequested` itself.
      emit(
        _withDocument(event.type, event.asset.toUploadable()).copyWith(
          failure: null,
        ),
      );
      return;
    }

    // Preserve whatever this slot held (e.g. an already-uploaded document
    // being replaced) so a failing check can restore it untouched — the
    // currently valid document must never be overwritten before the new one
    // passes (see `document_flow` pre-upload validation feature).
    final previous = state.documentAt(event.type);

    emit(
      _withDocument(
        event.type,
        event.asset.toUploadable().markValidating(),
      ).copyWith(failure: null),
    );

    DocumentValidationResult result;
    try {
      result = await validator.validate(event.asset, type: event.type);
    } on Object {
      result = const DocumentValidationResult.error();
    }

    if (isClosed) return;

    switch (result) {
      case DocumentValidationValid():
        final picked = event.asset.toUploadable();
        emit(_withDocument(event.type, picked).copyWith(failure: null));
        await _uploadDocument(event.type, picked, emit);
      case DocumentValidationInvalid():
        emit(
          _withDocument(event.type, previous).copyWith(
            failure: flow_failure.DocumentValidationFailure(
              messageKey: _invalidTypeMessageKey(event.type),
              kind: DocumentValidationFailureKind.invalidType,
            ),
          ),
        );
      case DocumentValidationError():
        emit(
          _withDocument(event.type, previous).copyWith(
            failure: const flow_failure.DocumentValidationFailure(
              messageKey: 'errors.document_validation.engine_error',
              kind: DocumentValidationFailureKind.engineError,
            ),
          ),
        );
    }
  }

  /// The localized message for a confident "wrong document type" rejection,
  /// specific to what the user was asked to provide.
  String _invalidTypeMessageKey(DocumentType type) => switch (type) {
    DocumentType.emiratesIdFront || DocumentType.emiratesIdBack =>
      'errors.document_validation.invalid_emirates_id',
    DocumentType.tradeLicense =>
      'errors.document_validation.invalid_trade_license',
    DocumentType.passport ||
    DocumentType.vehicleLicense ||
    DocumentType.other => 'errors.document_validation.invalid_document',
  };

  Future<void> _onUploadRequested(
    DocumentUploadRequested event,
    Emitter<DocumentFlowState> emit,
  ) async {
    final current = state.documentAt(event.type);
    if (current == null) return;
    await _uploadDocument(event.type, current, emit);
  }

  /// Runs the actual media upload for [type], starting from [current].
  ///
  /// Shared by [_onUploadRequested] (explicit, caller-triggered upload) and
  /// [_onPicked] (auto-triggered once a [DocumentTypeValidator] check
  /// passes) so both paths emit an identical uploading → uploaded/failed
  /// sequence.
  Future<void> _uploadDocument(
    DocumentType type,
    UploadableAsset current,
    Emitter<DocumentFlowState> emit,
  ) async {
    emit(
      _withDocument(type, current.markUploading()).copyWith(failure: null),
    );

    final result = await _uploadMedia(
      UploadMediaParams(
        type: type,
        filePath: current.asset.path,
        fileName: current.asset.name,
        mimeType: current.asset.mimeType,
        uploadKey: type.name,
        context: state.context,
        onProgress: (progress) {
          final inFlight = state.documentAt(type);
          if (inFlight == null || !inFlight.isUploading) return;
          emit(_withDocument(type, inFlight.markUploading(progress)));
        },
      ),
    ).run();

    if (isClosed) return;

    result.fold(
      (failure) {
        if (failure is NetworkFailure &&
            failure.message == 'errors.request_cancelled') {
          emit(_withDocument(type, null));
          return;
        }
        final inFlight = state.documentAt(type);
        final failed = (inFlight ?? current).markFailed(failure.message);
        emit(
          _withDocument(type, failed).copyWith(
            failure: flow_failure.UploadFailure(messageKey: failure.message),
          ),
        );
      },
      (media) {
        final inFlight = state.documentAt(type);
        if (inFlight == null) return;
        emit(
          _withDocument(
            type,
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
              extracted: ExtractedDocuments(
                sections: [
                  ExtractedDocument(
                    type: _conflictDocumentType,
                    fields: const [],
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

    await result.fold(
      (failure) => _handleSubmitFailure(failure, emit),
      (_) async => emit(state.copyWith(phase: const PhaseSuccess())),
    );
  }

  /// Routes a submit/confirm rejection to the right recovery, mirroring the
  /// backend's split between request-drift codes (silently re-extract),
  /// an already-registered identifier (flag inline, same as the analogous
  /// extraction-time case), and everything else (surface for the feature to
  /// handle, e.g. attributing a document-domain code to a specific section).
  ///
  /// `EXTRACTION_REQUIRED`/`EXTRACTION_STALE` mean the reviewed media drifted
  /// from what was last extracted (no prior extract, or the extraction cache
  /// expired/changed) — re-running extraction is the correct, transparent
  /// recovery; the review page already renders [PhaseExtracting] as the same
  /// animated view used for the first extraction, so this needs no bespoke
  /// UI. A 409 that is *not* `EXTRACTION_STALE` is the "identifier already
  /// registered to another account" case, handled the same way the
  /// extraction-time [ConflictFailure] already is.
  Future<void> _handleSubmitFailure(
    Failure failure,
    Emitter<DocumentFlowState> emit,
  ) async {
    final code = _codeOf(failure);

    if (code == 'EXTRACTION_REQUIRED' || code == 'EXTRACTION_STALE') {
      await _onExtractionRequested(const ExtractionRequested(), emit);
      return;
    }

    if (failure is ConflictFailure) {
      emit(
        state.copyWith(
          extracted: ExtractedDocuments(
            sections: [
              ExtractedDocument(
                type: _conflictDocumentType,
                fields: const [],
                issue: DocumentIssue.alreadyRegistered,
              ),
            ],
          ),
          phase: const PhaseExtracted(),
          failure: null,
        ),
      );
      return;
    }

    final metadata = failure.metadata;
    emit(
      state.copyWith(
        phase: const PhaseFailure(FailedStage.submit),
        failure: flow_failure.SubmitFailure(
          messageKey: failure.message,
          code: code,
          fields:
              (metadata?['fields'] as List?)
                  ?.map((e) => e.toString())
                  .toList() ??
              const [],
          requestId: metadata?['requestId']?.toString(),
        ),
      ),
    );
  }

  String? _codeOf(Failure failure) =>
      failure.metadata?['code']?.toString() ?? failure.code;

  /// Which document an "identifier already registered" conflict concerns,
  /// when the backend gives no structured way to tell (unlike
  /// `EXTRACTION_STALE`, this case has no dedicated `code`).
  ///
  /// A flow whose [DocumentFlowConfig.requiredDocuments] requires the trade
  /// licence but *not* the Emirates ID is unambiguous — a renewal scoped to
  /// only the trade licence (see `DocumentScope.tradeLicense` in
  /// organization settings) — so the conflict must be about that licence
  /// number. Every other flow (onboarding, whether individual or
  /// organization; a renewal scoped to the Emirates ID) always requires the
  /// Emirates ID, so it resolves there — this preserves onboarding's
  /// existing behavior exactly, since a conflict during organization
  /// onboarding has always meant the Emirates ID in practice.
  DocumentType get _conflictDocumentType {
    final required = state.config.requiredDocuments;
    if (required.contains(DocumentType.tradeLicense) &&
        !required.contains(DocumentType.emiratesIdFront)) {
      return DocumentType.tradeLicense;
    }
    return DocumentType.emiratesIdFront;
  }

  void _onReviewFlagged(
    ReviewFlagged event,
    Emitter<DocumentFlowState> emit,
  ) {
    emit(
      state.copyWith(
        extracted: event.extracted,
        phase: const PhaseExtracted(),
        failure: null,
      ),
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
