import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'branches_event.dart';
part 'branches_state.dart';

class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  BranchesBloc({
    required GetBranchesUseCase getBranchesUseCase,
    required DeleteBranchUseCase deleteBranchUseCase,
    required UpdateBranchStatusUseCase updateBranchStatusUseCase,
  })  : _getBranchesUseCase = getBranchesUseCase,
        _deleteBranchUseCase = deleteBranchUseCase,
        _updateBranchStatusUseCase = updateBranchStatusUseCase,
        super(const BranchesState()) {
    on<BranchesFetchEvent>(_onFetch);
    on<BranchesRefreshEvent>(_onRefresh);
    on<BranchesFilterChangedEvent>(_onFilterChanged);
    on<BranchesSearchChangedEvent>(_onSearchChanged);
    on<BranchDeletedEvent>(_onBranchDeleted);
    on<BranchStatusChangedEvent>(_onBranchStatusChanged);
    on<BranchActionFailureClearedEvent>(_onActionFailureCleared);
  }

  final GetBranchesUseCase _getBranchesUseCase;
  final DeleteBranchUseCase _deleteBranchUseCase;
  final UpdateBranchStatusUseCase _updateBranchStatusUseCase;

  Future<void> _onFetch(
    BranchesFetchEvent event,
    Emitter<BranchesState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _loadBranches(emit);
  }

  Future<void> _onRefresh(
    BranchesRefreshEvent event,
    Emitter<BranchesState> emit,
  ) async {
    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _loadBranches(emit);
  }

  void _onFilterChanged(
    BranchesFilterChangedEvent event,
    Emitter<BranchesState> emit,
  ) {
    emit(state.copyWith(filter: event.filter));
  }

  void _onSearchChanged(
    BranchesSearchChangedEvent event,
    Emitter<BranchesState> emit,
  ) {
    emit(state.copyWith(searchQuery: event.query));
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
            branches: updated,
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
            branches: updated,
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

  Future<void> _loadBranches(Emitter<BranchesState> emit) async {
    final result = await _getBranchesUseCase(
      const GetBranchesParams(limit: 50),
    ).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (paginated) => emit(
        state.copyWith(
          status: RequestStatus.success,
          branches: paginated.branches,
          meta: paginated.meta,
        ),
      ),
    );
  }
}
