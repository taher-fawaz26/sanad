import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/branches_query.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/workers.dart';

part 'assign_branch_event.dart';
part 'assign_branch_state.dart';

/// Owns the "assign worker → branch" sheet. Loads the branches the worker
/// could be added to, holds the current selection, and submits the update.
///
/// Emits [AssignBranchSaveSuccess] via the save-status transition — the
/// sheet consumes it in a [BlocListener] to pop with the updated worker
/// (rather than passing the worker through a `Navigator.pop` result).
class AssignBranchBloc extends Bloc<AssignBranchEvent, AssignBranchState> {
  AssignBranchBloc({
    required GetBranchesUseCase getBranchesUseCase,
    required UpdateBranchUseCase updateBranchUseCase,
    required WorkerEntity worker,
  }) : _getBranchesUseCase = getBranchesUseCase,
       _updateBranchUseCase = updateBranchUseCase,
       _worker = worker,
       super(const AssignBranchState()) {
    on<AssignBranchLoadEvent>(_onLoad, transformer: droppable());
    on<AssignBranchSelectedEvent>(_onSelected);
    on<AssignBranchSubmitEvent>(_onSubmit, transformer: droppable());
  }

  final GetBranchesUseCase _getBranchesUseCase;
  final UpdateBranchUseCase _updateBranchUseCase;
  final WorkerEntity _worker;

  WorkerEntity get worker => _worker;

  Future<void> _onLoad(
    AssignBranchLoadEvent event,
    Emitter<AssignBranchState> emit,
  ) async {
    emit(
      state.copyWith(
        loadStatus: RequestStatus.loading,
        clearLoadFailure: true,
      ),
    );
    final result = await _getBranchesUseCase(
      const BranchesQuery(limit: 50),
    ).run();
    result.fold(
      (failure) => emit(
        state.copyWith(
          loadStatus: RequestStatus.failure,
          loadFailure: failure,
        ),
      ),
      (page) => emit(
        state.copyWith(
          loadStatus: RequestStatus.success,
          branches: page.items,
        ),
      ),
    );
  }

  void _onSelected(
    AssignBranchSelectedEvent event,
    Emitter<AssignBranchState> emit,
  ) => emit(state.copyWith(selectedBranch: event.branch));

  Future<void> _onSubmit(
    AssignBranchSubmitEvent event,
    Emitter<AssignBranchState> emit,
  ) async {
    final branch = state.selectedBranch;
    if (branch == null) return;

    emit(
      state.copyWith(
        saveStatus: RequestStatus.loading,
        clearSaveFailure: true,
      ),
    );

    final updatedWorkerIds = [
      ...branch.workers.map((w) => w.id),
      _worker.id,
    ];

    final result = await _updateBranchUseCase(
      UpdateBranchParams(
        id: branch.id,
        branchName: branch.branchName,
        branchAddress: branch.branchAddress,
        branchPhone: branch.branchPhone,
        workerIds: updatedWorkerIds,
      ),
    ).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          saveStatus: RequestStatus.failure,
          saveFailure: failure,
        ),
      ),
      (_) {
        final updatedWorker = WorkerEntity(
          id: _worker.id,
          fullName: _worker.fullName,
          role: _worker.role,
          initials: _worker.initials,
          status: _worker.status,
          phone: _worker.phone,
          email: _worker.email,
          jobTitle: _worker.jobTitle,
          profilePicUrl: _worker.profilePicUrl,
          assignedBranches: [
            ..._worker.assignedBranches,
            WorkerAssignedBranch(
              id: branch.id,
              branchName: branch.branchName,
              role: 'worker',
            ),
          ],
        );
        emit(
          state.copyWith(
            saveStatus: RequestStatus.success,
            updatedWorker: updatedWorker,
          ),
        );
      },
    );
  }
}
