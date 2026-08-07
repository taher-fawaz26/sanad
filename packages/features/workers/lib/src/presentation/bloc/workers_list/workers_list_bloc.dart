import 'dart:async';

import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';

part 'workers_list_event.dart';
part 'workers_list_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Owns the workers list: fetch, refresh, load-more, search, and single-worker
/// replacement after an edit.
///
/// **Does not** own worker mutations (delete / suspend / unsuspend) — those
/// live in `WorkerActionCubit`. Success from an action cubit is applied to
/// this bloc via [WorkerRemovedFromListEvent] / [WorkerReplacedInListEvent],
/// which the page wires up in its effect listener.
class WorkersListBloc extends Bloc<WorkersListEvent, WorkersListState> {
  WorkersListBloc({required GetWorkersUseCase getWorkersUseCase})
    : _getWorkersUseCase = getWorkersUseCase,
      super(const WorkersListState()) {
    on<WorkersListFetchEvent>(_onFetch);
    on<WorkersListRefreshEvent>(_onRefresh);
    on<WorkersListLoadMoreEvent>(_onLoadMore);
    on<WorkersListSearchChangedEvent>(_onSearchChanged);
    on<WorkerReplacedInListEvent>(_onReplaced);
    on<WorkerRemovedFromListEvent>(_onRemoved);
  }

  final GetWorkersUseCase _getWorkersUseCase;
  Timer? _searchTimer;

  String? get _search =>
      state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim();

  @override
  Future<void> close() {
    _searchTimer?.cancel();
    return super.close();
  }

  Future<void> _onFetch(
    WorkersListFetchEvent event,
    Emitter<WorkersListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onRefresh(
    WorkersListRefreshEvent event,
    Emitter<WorkersListState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _fetch(emit, page: 1, append: false);
  }

  Future<void> _onLoadMore(
    WorkersListLoadMoreEvent event,
    Emitter<WorkersListState> emit,
  ) async {
    if (state.loadingMore || !state.hasMore) return;
    emit(state.copyWith(loadingMore: true));
    await _fetch(emit, page: state.page + 1, append: true);
  }

  void _onSearchChanged(
    WorkersListSearchChangedEvent event,
    Emitter<WorkersListState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
    _searchTimer?.cancel();
    _searchTimer = Timer(_searchDebounce, () {
      if (isClosed) return;
      add(const WorkersListFetchEvent());
    });
  }

  void _onReplaced(
    WorkerReplacedInListEvent event,
    Emitter<WorkersListState> emit,
  ) {
    final updated = state.workers
        .map((w) => w.id == event.worker.id ? event.worker : w)
        .toList();
    emit(state.copyWith(workers: updated));
  }

  void _onRemoved(
    WorkerRemovedFromListEvent event,
    Emitter<WorkersListState> emit,
  ) {
    final updated = state.workers.where((w) => w.id != event.workerId).toList();
    emit(state.copyWith(workers: updated));
  }

  Future<void> _fetch(
    Emitter<WorkersListState> emit, {
    required int page,
    required bool append,
  }) async {
    final result = await _getWorkersUseCase(
      GetWorkersParams(page: page, search: _search),
    ).run();

    result.fold(
      (failure) => emit(
        append
            ? state.copyWith(loadingMore: false)
            : state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (paged) => emit(
        state.copyWith(
          status: RequestStatus.success,
          workers: append ? [...state.workers, ...paged.items] : paged.items,
          page: paged.currentPage,
          totalPages: paged.totalPages,
          loadingMore: false,
        ),
      ),
    );
  }
}
