import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/branch_filter.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/branches_query.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fpdart/fpdart.dart';

part 'branches_event.dart';
part 'branches_state.dart';

/// Debounce applied to search keystrokes before hitting the server.
const _searchDebounce = Duration(milliseconds: 350);

class BranchesBloc extends Bloc<BranchesEvent, BranchesState>
    with
        PaginationMixin<
          BranchesEvent,
          BranchesState,
          BranchEntity,
          BranchesQuery
        > {
  BranchesBloc({
    required GetBranchesUseCase getBranchesUseCase,
    required DeleteBranchUseCase deleteBranchUseCase,
    required UpdateBranchStatusUseCase updateBranchStatusUseCase,
  }) : _getBranchesUseCase = getBranchesUseCase,
       _deleteBranchUseCase = deleteBranchUseCase,
       _updateBranchStatusUseCase = updateBranchStatusUseCase,
       super(const BranchesState()) {
    on<BranchesFetchEvent>((event, emit) => loadFirstPage(emit));
    on<BranchesRefreshEvent>(
      (event, emit) => refresh(emit),
      transformer: droppable(),
    );
    on<BranchesLoadMoreEvent>(
      (event, emit) => loadNextPage(emit),
      transformer: droppable(),
    );
    on<BranchesFilterChangedEvent>(
      _onFilterChanged,
      transformer: restartable(),
    );
    on<BranchesSearchChangedEvent>(
      _onSearchChanged,
      transformer: restartable(),
    );
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<BranchDeletedEvent>(_onBranchDeleted, transformer: droppable());
    on<BranchStatusChangedEvent>(
      _onBranchStatusChanged,
      transformer: droppable(),
    );
    on<BranchActionFailureClearedEvent>(_onActionFailureCleared);
  }

  final GetBranchesUseCase _getBranchesUseCase;
  final DeleteBranchUseCase _deleteBranchUseCase;
  final UpdateBranchStatusUseCase _updateBranchStatusUseCase;

  Future<void> _onFilterChanged(
    BranchesFilterChangedEvent event,
    Emitter<BranchesState> emit,
  ) async {
    if (event.filter == state.filter) return;
    emit(state.copyWith(filter: event.filter));
    await onQueryChanged(emit);
  }

  Future<void> _onSearchChanged(
    BranchesSearchChangedEvent event,
    Emitter<BranchesState> emit,
  ) async {
    emit(state.copyWith(searchQuery: event.query));
    await Future<void>.delayed(_searchDebounce);
    await onQueryChanged(emit);
  }

  Future<void> _onBranchDeleted(
    BranchDeletedEvent event,
    Emitter<BranchesState> emit,
  ) async {
    final result = await _deleteBranchUseCase(
      DeleteBranchParams(id: event.branchId),
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(actionFailure: failure)),
      (_) {
        final updated = state.branches
            .where((b) => b.id != event.branchId)
            .toList();
        emit(
          state.copyWith(
            pagination: state.pagination.copyWith(items: updated),
            clearActionFailure: true,
          ),
        );
      },
    );
  }

  Future<void> _onBranchStatusChanged(
    BranchStatusChangedEvent event,
    Emitter<BranchesState> emit,
  ) async {
    final result = await _updateBranchStatusUseCase(
      UpdateBranchStatusParams(
        id: event.branchId,
        isAvailable: event.isAvailable,
      ),
    ).run();

    result.fold(
      (failure) => emit(state.copyWith(actionFailure: failure)),
      (branch) {
        final updated = state.branches
            .map((b) => b.id == branch.id ? branch : b)
            .toList();
        emit(
          state.copyWith(
            pagination: state.pagination.copyWith(items: updated),
            clearActionFailure: true,
          ),
        );
      },
    );
  }

  void _onActionFailureCleared(
    BranchActionFailureClearedEvent event,
    Emitter<BranchesState> emit,
  ) {
    emit(state.copyWith(clearActionFailure: true));
  }

  @override
  PaginationData<BranchEntity> readPage(BranchesState state) =>
      state.pagination;

  @override
  BranchesState writePage(
    BranchesState state,
    PaginationData<BranchEntity> data,
  ) => state.copyWith(pagination: data);

  @override
  BranchesQuery buildQuery({required int page}) {
    final trimmed = state.searchQuery.trim();
    return BranchesQuery(
      page: page,
      search: trimmed.isEmpty ? null : trimmed,
      filter: state.filter,
    );
  }

  @override
  TaskEither<Failure, Page<BranchEntity>> fetchPage(BranchesQuery query) =>
      _getBranchesUseCase(query);

  @override
  Object dedupKey(BranchEntity item) => item.id;
}
