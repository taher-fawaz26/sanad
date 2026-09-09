import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/repositories/client_requests_repository.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/usecases/client_request_usecases.dart';

part 'request_draft_event.dart';
part 'request_draft_state.dart';

/// The draft composer: build a request, save it partially, then submit.
///
/// Two rules shape this bloc:
///
/// * **A partial draft is valid.** Editing a field saves only that field, and
///   nothing runs submit-time validation until the user actually submits.
/// * **A failed mutation never clears entered input.** The form state is what
///   the user typed; only a successful server response replaces it.
class RequestDraftBloc extends Bloc<RequestDraftEvent, RequestDraftState> {
  /// Creates the composer, optionally seeded with an existing request.
  RequestDraftBloc({
    required CreateDraftRequestUseCase createDraft,
    required UpdateDraftRequestUseCase updateDraft,
    required SubmitRequestUseCase submitRequest,
    required GetClientRequestUseCase getRequest,
    ClientRequest? initial,
  }) : _createDraft = createDraft,
       _updateDraft = updateDraft,
       _submitRequest = submitRequest,
       _getRequest = getRequest,
       super(RequestDraftState.fromRequest(initial)) {
    on<RequestDraftLoaded>(_onLoaded, transformer: restartable());
    on<RequestDraftServiceChanged>(_onServiceChanged);
    on<RequestDraftLocationChanged>(_onLocationChanged);
    on<RequestDraftPreferredAtChanged>(_onPreferredAtChanged);
    on<RequestDraftNoteChanged>(_onNoteChanged);
    on<RequestDraftMediaChanged>(_onMediaChanged);
    // droppable(): a double-tapped Save must not create two drafts.
    on<RequestDraftSaved>(_onSaved, transformer: droppable());
    on<RequestDraftSubmitted>(_onSubmitted, transformer: droppable());
    on<RequestDraftConflictDismissed>(
      (_, emit) => emit(state.copyWith(clearSubmissionConflict: true)),
    );
  }

  final CreateDraftRequestUseCase _createDraft;
  final UpdateDraftRequestUseCase _updateDraft;
  final SubmitRequestUseCase _submitRequest;
  final GetClientRequestUseCase _getRequest;

  Future<void> _onLoaded(
    RequestDraftLoaded event,
    Emitter<RequestDraftState> emit,
  ) async {
    emit(state.copyWith(loadStatus: RequestStatus.loading));
    final result = await _getRequest(event.id).run();
    result.match(
      (failure) => emit(
        state.copyWith(loadStatus: RequestStatus.failure, loadFailure: failure),
      ),
      (request) => emit(
        RequestDraftState.fromRequest(
          request,
        ).copyWith(loadStatus: RequestStatus.success),
      ),
    );
  }

  void _onServiceChanged(
    RequestDraftServiceChanged event,
    Emitter<RequestDraftState> emit,
  ) => emit(
    state.copyWith(
      serviceId: event.serviceId,
      serviceName: event.serviceName,
      isDirty: true,
      // Picking a different service is the recovery action for
      // NO_PROVIDERS_FOR_SERVICE, so the banner has served its purpose.
      clearSubmissionConflict: true,
    ),
  );

  void _onLocationChanged(
    RequestDraftLocationChanged event,
    Emitter<RequestDraftState> emit,
  ) => emit(
    state.copyWith(
      lat: event.lat,
      lng: event.lng,
      addressLine: event.addressLine,
      isDirty: true,
      // Likewise the recovery action for NO_COVERAGE.
      clearSubmissionConflict: true,
    ),
  );

  void _onPreferredAtChanged(
    RequestDraftPreferredAtChanged event,
    Emitter<RequestDraftState> emit,
  ) => emit(
    state.copyWith(
      preferredAt: event.preferredAt,
      isDirty: true,
      // And for OUTSIDE_HOURS — including when the new time came from tapping
      // one of the alternatives the conflict itself offered.
      clearSubmissionConflict: true,
    ),
  );

  void _onNoteChanged(
    RequestDraftNoteChanged event,
    Emitter<RequestDraftState> emit,
  ) => emit(state.copyWith(note: event.note, isDirty: true));

  void _onMediaChanged(
    RequestDraftMediaChanged event,
    Emitter<RequestDraftState> emit,
  ) => emit(
    state.copyWith(
      mediaIds: event.mediaIds,
      mediaIdsResolved: true,
      isDirty: true,
    ),
  );

  Future<void> _onSaved(
    RequestDraftSaved event,
    Emitter<RequestDraftState> emit,
  ) async {
    emit(
      state.copyWith(
        saveStatus: RequestStatus.loading,
        clearSaveFailure: true,
      ),
    );
    final result = await _save().run();
    result.match(
      // Note what is NOT done here: the entered fields are untouched, so the
      // user can fix the problem and retry without retyping anything.
      (failure) => emit(
        state.copyWith(
          saveStatus: RequestStatus.failure,
          saveFailure: failure,
        ),
      ),
      (request) => emit(
        RequestDraftState.fromRequest(
          request,
        ).copyWith(saveStatus: RequestStatus.success),
      ),
    );
  }

  Future<void> _onSubmitted(
    RequestDraftSubmitted event,
    Emitter<RequestDraftState> emit,
  ) async {
    emit(
      state.copyWith(
        submitStatus: RequestStatus.loading,
        clearSubmitFailure: true,
        clearSubmissionConflict: true,
      ),
    );

    // Submitting a draft that has unsaved edits has to persist them first —
    // the server validates what it stored, not what is on screen.
    final saved = await _save().run();
    final savedRequest = saved.toNullable();
    if (savedRequest == null) {
      final failure = saved.getLeft().toNullable()!;
      emit(
        state.copyWith(
          submitStatus: RequestStatus.failure,
          submitFailure: failure,
        ),
      );
      return;
    }
    emit(
      RequestDraftState.fromRequest(savedRequest).copyWith(
        submitStatus: RequestStatus.loading,
      ),
    );

    final result = await _submitRequest(savedRequest.id).run();
    result.match(
      (failure) => emit(
        state.copyWith(
          submitStatus: RequestStatus.failure,
          submitFailure: failure,
          // A 409 here is a structured matching failure whose code decides
          // what the UI offers next. Parsing it out preserves that instead of
          // collapsing it into one generic message.
          submissionConflict: RequestSubmissionConflict.tryParse(failure),
        ),
      ),
      (request) => emit(
        RequestDraftState.fromRequest(
          request,
        ).copyWith(submitStatus: RequestStatus.success),
      ),
    );
  }

  /// Creates the draft on first save, patches it afterwards.
  TaskEither<Failure, ClientRequest> _save() {
    final params = SaveDraftParams(
      serviceId: state.serviceId,
      lat: state.lat,
      lng: state.lng,
      addressLine: state.addressLine,
      preferredAt: state.preferredAt,
      note: state.note,
      // Omitted until the set is real: `mediaIds` replaces the whole
      // attachment list, so sending the empty default from a save that had
      // nothing to do with attachments would detach every file.
      mediaIds: state.mediaIdsResolved ? state.mediaIds : null,
    );
    final id = state.requestId;
    return id == null
        ? _createDraft(params)
        : _updateDraft(UpdateDraftParams(id: id, changes: params));
  }
}
