import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_status_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_usecase.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'branch_details_event.dart';
part 'branch_details_state.dart';

class BranchDetailsBloc extends Bloc<BranchDetailsEvent, BranchDetailsState> {
  BranchDetailsBloc({
    required GetBranchUseCase getBranchUseCase,
    required UpdateBranchStatusUseCase updateBranchStatusUseCase,
    required UpdateBranchUseCase updateBranchUseCase,
  }) : _getBranchUseCase = getBranchUseCase,
       _updateBranchStatusUseCase = updateBranchStatusUseCase,
       _updateBranchUseCase = updateBranchUseCase,
       super(const BranchDetailsState()) {
    on<BranchDetailsFetchEvent>(_onFetch);
    on<BranchDetailsRefreshEvent>(_onRefresh);
    // Drop duplicate submits while one is in flight (double-tap guard).
    on<BranchStatusToggleEvent>(_onStatusToggle, transformer: droppable());
    on<BranchSectionUpdated>(_onSectionUpdated, transformer: droppable());
  }

  final GetBranchUseCase _getBranchUseCase;
  final UpdateBranchStatusUseCase _updateBranchStatusUseCase;
  final UpdateBranchUseCase _updateBranchUseCase;

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

  Future<void> _onStatusToggle(
    BranchStatusToggleEvent event,
    Emitter<BranchDetailsState> emit,
  ) async {
    final branchId = state.branchId;
    if (branchId == null) return;

    emit(
      state.copyWith(statusUpdateLoading: true, clearStatusUpdateFailure: true),
    );

    final result = await _updateBranchStatusUseCase(
      UpdateBranchStatusParams(id: branchId, isAvailable: event.isAvailable),
    ).run();

    result.fold(
      (failure) => emit(
        state.copyWith(
          statusUpdateLoading: false,
          statusUpdateFailure: failure,
        ),
      ),
      (branch) => emit(
        state.copyWith(
          statusUpdateLoading: false,
          branch: branch,
        ),
      ),
    );
  }

  Future<void> _onSectionUpdated(
    BranchSectionUpdated event,
    Emitter<BranchDetailsState> emit,
  ) async {
    emit(
      state.copyWith(
        sectionSaveStatus: RequestStatus.loading,
        clearSectionSaveFailure: true,
      ),
    );

    final result = await _updateBranchUseCase(event.params).run();

    final failure = result.fold((failure) => failure, (_) => null);
    if (failure != null) {
      emit(
        state.copyWith(
          sectionSaveStatus: RequestStatus.failure,
          sectionSaveFailure: failure,
        ),
      );
      return;
    }

    // Never trust the local params as the new state — re-fetch the
    // canonical branch so server normalization is reflected on screen.
    final refreshed = await _loadBranch(event.params.id, emit);
    emit(
      state.copyWith(
        sectionSaveStatus: refreshed
            ? RequestStatus.success
            : RequestStatus.failure,
      ),
    );
  }

  /// Fetches [branchId] and emits the result into the page-level `status`.
  /// Returns whether the fetch succeeded, so callers with their own status
  /// tracking (e.g. section-save) can tell a failed rehydration apart from
  /// a successful one.
  Future<bool> _loadBranch(
    String branchId,
    Emitter<BranchDetailsState> emit,
  ) async {
    final result = await _getBranchUseCase(
      GetBranchParams(id: branchId),
    ).run();

    return result.fold(
      (failure) {
        emit(state.copyWith(status: RequestStatus.failure, failure: failure));
        return false;
      },
      (branch) {
        emit(state.copyWith(status: RequestStatus.success, branch: branch));
        return true;
      },
    );
  }
}
