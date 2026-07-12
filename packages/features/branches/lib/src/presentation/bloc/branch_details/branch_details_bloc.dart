import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'branch_details_event.dart';
part 'branch_details_state.dart';

class BranchDetailsBloc extends Bloc<BranchDetailsEvent, BranchDetailsState> {
  BranchDetailsBloc({required GetBranchUseCase getBranchUseCase})
      : _getBranchUseCase = getBranchUseCase,
        super(const BranchDetailsState()) {
    on<BranchDetailsFetchEvent>(_onFetch);
    on<BranchDetailsRefreshEvent>(_onRefresh);
  }

  final GetBranchUseCase _getBranchUseCase;

  Future<void> _onFetch(
    BranchDetailsFetchEvent event,
    Emitter<BranchDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        branchId: event.branchId,
        status: RequestStatus.loading,
        clearFailure: true,
      ),
    );
    await _loadBranch(event.branchId, emit);
  }

  Future<void> _onRefresh(
    BranchDetailsRefreshEvent event,
    Emitter<BranchDetailsState> emit,
  ) async {
    final branchId = state.branchId;
    if (branchId == null) return;

    emit(state.copyWith(status: RequestStatus.loading, clearFailure: true));
    await _loadBranch(branchId, emit);
  }

  Future<void> _loadBranch(
    String branchId,
    Emitter<BranchDetailsState> emit,
  ) async {
    final result = await _getBranchUseCase(
      GetBranchParams(id: branchId),
    ).run();

    result.fold(
      (failure) => emit(
        state.copyWith(status: RequestStatus.failure, failure: failure),
      ),
      (branch) => emit(
        state.copyWith(
          status: RequestStatus.success,
          branch: branch,
        ),
      ),
    );
  }
}
