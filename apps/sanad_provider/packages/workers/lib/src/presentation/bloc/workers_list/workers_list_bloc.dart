import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';
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
class WorkersListBloc extends Bloc<WorkersListEvent, WorkersListState>
    with
        PaginationMixin<
          WorkersListEvent,
          WorkersListState,
          WorkerEntity,
          WorkersQuery
        > {
  WorkersListBloc({required GetWorkersUseCase getWorkersUseCase})
    : _getWorkersUseCase = getWorkersUseCase,
      super(const WorkersListState()) {
    on<WorkersListFetchEvent>((event, emit) => loadFirstPage(emit));
    on<WorkersListRefreshEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<WorkersListLoadMoreEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<WorkersListSearchChangedEvent>(
      _onSearchChanged,
      transformer: restartable(),
    );
    on<WorkerReplacedInListEvent>(_onReplaced);
    on<WorkerRemovedFromListEvent>(_onRemoved);
  }

  final GetWorkersUseCase _getWorkersUseCase;

  Future<void> _onSearchChanged(
    WorkersListSearchChangedEvent event,
    Emitter<WorkersListState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  void _onReplaced(
    WorkerReplacedInListEvent event,
    Emitter<WorkersListState> emit,
  ) {
    final updated = state.workers
        .map((w) => w.id == event.worker.id ? event.worker : w)
        .toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  void _onRemoved(
    WorkerRemovedFromListEvent event,
    Emitter<WorkersListState> emit,
  ) {
    final updated = state.workers.where((w) => w.id != event.workerId).toList();
    emit(state.copyWith(pagination: state.pagination.copyWith(items: updated)));
  }

  @override
  PaginationData<WorkerEntity> readPage(WorkersListState state) =>
      state.pagination;

  @override
  WorkersListState writePage(
    WorkersListState state,
    PaginationData<WorkerEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  WorkersQuery buildQuery({required int page}) => WorkersQuery(
    page: page,
    search: state.searchQuery.trim().isEmpty ? null : state.searchQuery.trim(),
  );

  @override
  TaskEither<Failure, Page<WorkerEntity>> fetchPage(WorkersQuery query) =>
      _getWorkersUseCase(query);
}
