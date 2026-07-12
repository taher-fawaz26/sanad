import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/entities/paginated_branches_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/delete_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'branches_event.dart';
part 'branches_state.dart';

class BranchesBloc extends Bloc<BranchesEvent, BranchesState> {
  BranchesBloc({
    required GetBranchesUseCase getBranchesUseCase,
    required DeleteBranchUseCase deleteBranchUseCase,
  })  : _getBranchesUseCase = getBranchesUseCase,
        _deleteBranchUseCase = deleteBranchUseCase,
        super(const BranchesState()) {
    on<BranchesFetchEvent>(_onFetch);
    on<BranchesRefreshEvent>(_onRefresh);
    on<BranchesFilterChangedEvent>(_onFilterChanged);
    on<BranchesSearchChangedEvent>(_onSearchChanged);
    on<BranchDeletedEvent>(_onBranchDeleted);
  }

  final GetBranchesUseCase _getBranchesUseCase;
  final DeleteBranchUseCase _deleteBranchUseCase;

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
      (failure) => emit(state.copyWith(failure: failure)),
      (_) {
        final updated = state.branches
            .where((b) => b.id != event.branchId)
            .toList();
        emit(state.copyWith(branches: updated));
      },
    );
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
