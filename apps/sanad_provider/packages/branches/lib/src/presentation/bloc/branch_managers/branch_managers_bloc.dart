import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/usecases/branch_managers_query.dart';
import 'package:branches/src/domain/usecases/get_branch_managers_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'branch_managers_event.dart';
part 'branch_managers_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

/// Owns the paginated branch-manager picker: first page, refresh, load-more,
/// and server-side search. `restartable()` on search + `PaginationMixin`'s
/// own epoch guard supersede the widget-level `Timer`/`_generation` guards
/// this replaces.
class BranchManagersBloc extends Bloc<BranchManagersEvent, BranchManagersState>
    with
        PaginationMixin<
          BranchManagersEvent,
          BranchManagersState,
          BranchManagerEntity,
          BranchManagersQuery
        > {
  BranchManagersBloc({
    required GetBranchManagersUseCase getBranchManagersUseCase,
  }) : _getBranchManagersUseCase = getBranchManagersUseCase,
       super(const BranchManagersState()) {
    on<BranchManagersFetchEvent>((event, emit) => loadFirstPage(emit));
    on<BranchManagersRefreshEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<BranchManagersLoadMoreEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<BranchManagersSearchChangedEvent>(
      _onSearchChanged,
      transformer: restartable(),
    );
  }

  final GetBranchManagersUseCase _getBranchManagersUseCase;

  Future<void> _onSearchChanged(
    BranchManagersSearchChangedEvent event,
    Emitter<BranchManagersState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  @override
  PaginationData<BranchManagerEntity> readPage(BranchManagersState state) =>
      state.pagination;

  @override
  BranchManagersState writePage(
    BranchManagersState state,
    PaginationData<BranchManagerEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  BranchManagersQuery buildQuery({required int page}) {
    final trimmed = state.searchQuery.trim();
    return BranchManagersQuery(
      page: page,
      search: trimmed.isEmpty ? null : trimmed,
    );
  }

  @override
  TaskEither<Failure, Page<BranchManagerEntity>> fetchPage(
    BranchManagersQuery query,
  ) => _getBranchManagersUseCase(query);

  @override
  Object dedupKey(BranchManagerEntity item) => item.id;
}
