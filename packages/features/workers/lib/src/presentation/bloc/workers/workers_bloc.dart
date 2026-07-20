import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/domain/usecases/cancel_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/delete_worker_usecase.dart';
import 'package:workers/src/domain/usecases/get_invitations_usecase.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';
import 'package:workers/src/domain/usecases/resend_invitation_usecase.dart';
import 'package:workers/src/domain/usecases/update_worker_status_usecase.dart';

part 'workers_event.dart';
part 'workers_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

class WorkersBloc extends Bloc<WorkersEvent, WorkersState> {
  WorkersBloc({
    required GetWorkersUseCase getWorkersUseCase,
    required DeleteWorkerUseCase deleteWorkerUseCase,
    required UpdateWorkerStatusUseCase updateWorkerStatusUseCase,
    required GetInvitationsUseCase getInvitationsUseCase,
    required ResendInvitationUseCase resendInvitationUseCase,
    required CancelInvitationUseCase cancelInvitationUseCase,
  }) : _getWorkersUseCase = getWorkersUseCase,
       _deleteWorkerUseCase = deleteWorkerUseCase,
       _updateWorkerStatusUseCase = updateWorkerStatusUseCase,
       _getInvitationsUseCase = getInvitationsUseCase,
       _resendInvitationUseCase = resendInvitationUseCase,
       _cancelInvitationUseCase = cancelInvitationUseCase,
       super(const WorkersState()) {
    on<WorkersFetchEvent>(_onFetch);
    on<WorkersRefreshEvent>(_onRefresh);
    on<WorkersLoadMoreEvent>(_onWorkersLoadMore);
    on<WorkersSearchChangedEvent>(_onSearchChanged);
    on<WorkerDeletedEvent>(_onWorkerDeleted);
    on<WorkerStatusChangedEvent>(_onWorkerStatusChanged);
    on<WorkerActionFailureClearedEvent>(_onActionFailureCleared);
    on<WorkersTabChangedEvent>(_onTabChanged);
    on<InvitationsFetchEvent>(_onInvitationsFetch);
    on<InvitationsRefreshEvent>(_onInvitationsRefresh);
    on<InvitationsLoadMoreEvent>(_onInvitationsLoadMore);
    on<InvitationResendEvent>(_onInvitationResend);
    on<InvitationCancelledEvent>(_onInvitationCancelled);
  }

  final GetWorkersUseCase _getWorkersUseCase;
  final DeleteWorkerUseCase _deleteWorkerUseCase;
  final UpdateWorkerStatusUseCase _updateWorkerStatusUseCase;
  final GetInvitationsUseCase _getInvitationsUseCase;
  final ResendInvitationUseCase _resendInvitationUseCase;
  final CancelInvitationUseCase _cancelInvitationUseCase;

  Timer? _searchTimer;

  String? get _search =>
      state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim();

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onFetch(
    WorkersFetchEvent event,
    Emitter<WorkersState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetchWorkers(emit, page: 1, append: false);
  }

  Future<void> _onRefresh(
    WorkersRefreshEvent event,
    Emitter<WorkersState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetchWorkers(emit, page: 1, append: false);
  }

  Future<void> _onWorkersLoadMore(
    WorkersLoadMoreEvent event,
    Emitter<WorkersState> emit,
  ) async {
    if (state.workersLoadingMore || !state.workersHasMore) return;
    emit(state.copyWith(workersLoadingMore: true));
    await _fetchWorkers(emit, page: state.workersPage + 1, append: true);
  }

  void _onSearchChanged(
    WorkersSearchChangedEvent event,
    Emitter<WorkersState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (isClosed) return;
      add(
        state.isInvitationsTab
            ? const InvitationsFetchEvent()
            : const WorkersFetchEvent(),
      );
    });
  }

  Future<void> _onWorkerDeleted(
    WorkerDeletedEvent event,
    Emitter<WorkersState> emit,
  ) async {
    final result = await _deleteWorkerUseCase(
      DeleteWorkerParams(id: event.workerId),
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(actionFailure: failure)),
      (_) {
        final updated = state.workers
            .where((w) => w.id != event.workerId)
            .toList();
        emit(state.copyWith(workers: updated, clearActionFailure: true));
      },
    );
  }

  Future<void> _onWorkerStatusChanged(
    WorkerStatusChangedEvent event,
    Emitter<WorkersState> emit,
  ) async {
    final result = await _updateWorkerStatusUseCase(
      UpdateWorkerStatusParams(id: event.workerId, status: event.status),
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(actionFailure: failure)),
      (worker) {
        final updated = state.workers
            .map((w) => w.id == worker.id ? worker : w)
            .toList();
        emit(state.copyWith(workers: updated, clearActionFailure: true));
      },
    );
  }

  void _onActionFailureCleared(
    WorkerActionFailureClearedEvent event,
    Emitter<WorkersState> emit,
  ) {
    emit(state.copyWith(clearActionFailure: true));
  }

  void _onTabChanged(
    WorkersTabChangedEvent event,
    Emitter<WorkersState> emit,
  ) {
    emit(state.copyWith(selectedTab: event.tabIndex));
    if (event.tabIndex == 1 &&
        state.invitationsStatus == RequestStatus.initial) {
      add(const InvitationsFetchEvent());
    }
  }

  Future<void> _onInvitationsFetch(
    InvitationsFetchEvent event,
    Emitter<WorkersState> emit,
  ) async {
    emit(
      state.copyWith(
        invitationsStatus: RequestStatus.loading,
        clearFailure: true,
      ),
    );
    await _fetchInvitations(emit, page: 1, append: false);
  }

  Future<void> _onInvitationsRefresh(
    InvitationsRefreshEvent event,
    Emitter<WorkersState> emit,
  ) async {
    emit(
      state.copyWith(
        invitationsStatus: RequestStatus.loading,
        clearFailure: true,
      ),
    );
    await _fetchInvitations(emit, page: 1, append: false);
  }

  Future<void> _onInvitationsLoadMore(
    InvitationsLoadMoreEvent event,
    Emitter<WorkersState> emit,
  ) async {
    if (state.invitationsLoadingMore || !state.invitationsHasMore) return;
    emit(state.copyWith(invitationsLoadingMore: true));
    await _fetchInvitations(
      emit,
      page: state.invitationsPage + 1,
      append: true,
    );
  }

  Future<void> _onInvitationResend(
    InvitationResendEvent event,
    Emitter<WorkersState> emit,
  ) async {
    final result = await _resendInvitationUseCase(
      ResendInvitationParams(id: event.invitationId),
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(actionFailure: failure)),
      (_) => emit(state.copyWith(clearActionFailure: true)),
    );
  }

  Future<void> _onInvitationCancelled(
    InvitationCancelledEvent event,
    Emitter<WorkersState> emit,
  ) async {
    final result = await _cancelInvitationUseCase(
      CancelInvitationParams(id: event.invitationId),
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(actionFailure: failure)),
      (_) {
        final updated = state.invitations
            .where((i) => i.id != event.invitationId)
            .toList();
        emit(
          state.copyWith(
            invitations: updated,
            clearActionFailure: true,
          ),
        );
      },
    );
  }

  Future<void> _fetchWorkers(
    Emitter<WorkersState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _getWorkersUseCase(
      GetWorkersParams(page: page, search: _search),
    ).run();

    result.fold(
      (failure) => emit(
        append
            ? state.copyWith(workersLoadingMore: false)
            : state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (paged) => emit(
        state.copyWith(
          status: RequestStatus.success,
          workers: append ? [...state.workers, ...paged.items] : paged.items,
          workersPage: paged.currentPage,
          workersTotalPages: paged.totalPages,
          workersLoadingMore: false,
        ),
      ),
    );
  }

  Future<void> _fetchInvitations(
    Emitter<WorkersState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _getInvitationsUseCase(
      GetInvitationsParams(page: page, search: _search),
    ).run();

    result.fold(
      (failure) => emit(
        append
            ? state.copyWith(invitationsLoadingMore: false)
            : state.copyWith(
                invitationsStatus: RequestStatus.failure,
                failure: failure,
              ),
      ),
      (paged) => emit(
        state.copyWith(
          invitationsStatus: RequestStatus.success,
          invitations: append
              ? [...state.invitations, ...paged.items]
              : paged.items,
          invitationsPage: paged.currentPage,
          invitationsTotalPages: paged.totalPages,
          invitationsLoadingMore: false,
        ),
      ),
    );
  }
}
