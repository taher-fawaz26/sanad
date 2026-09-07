import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branch_usecase.dart';
import 'package:branches/src/domain/usecases/get_company_schedule_usecase.dart';
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
    required GetCompanyScheduleUseCase getCompanyScheduleUseCase,
  }) : _getBranchUseCase = getBranchUseCase,
       _updateBranchStatusUseCase = updateBranchStatusUseCase,
       _updateBranchUseCase = updateBranchUseCase,
       _getCompanyScheduleUseCase = getCompanyScheduleUseCase,
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
  final GetCompanyScheduleUseCase _getCompanyScheduleUseCase;

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

    final branch = result.fold((_) => null, (branch) => branch);
    if (branch == null) {
      final failure = result.fold((failure) => failure, (_) => null);
      emit(state.copyWith(status: RequestStatus.failure, failure: failure));
      return false;
    }

    // Resolve the effective schedule BEFORE surfacing success. Company-hours
    // branches keep their hours in the org company schedule (their own
    // `availability` is empty), so emitting success first would render a
    // transient "all days closed" frame until the schedule arrived. Fetching
    // it up front keeps the skeleton up until the real hours are ready
    // (SAN-780). Custom branches skip the fetch and resolve to `null` here.
    final companySchedule = await _resolveCompanySchedule(branch);

    emit(
      state.copyWith(
        status: RequestStatus.success,
        branch: branch,
        companySchedule: companySchedule,
      ),
    );
    return true;
  }

  /// Resolves the org-wide company schedule for a company-hours [branch] —
  /// its effective schedule lives there rather than on the branch payload
  /// ([BranchEntity.availability] is empty for them), so the details view can
  /// render the real hours instead of showing every day as closed (SAN-780).
  ///
  /// Returns `null` (skipping the fetch) for custom-schedule branches, which
  /// carry their own hours, and returns the already-cached schedule on a
  /// refresh so it is fetched at most once. A failed fetch is non-fatal and
  /// also returns `null`: the section falls back to whatever the branch
  /// payload carries. Because [BranchDetailsState.copyWith] treats a `null`
  /// `companySchedule` as "unchanged", returning `null` here never clobbers a
  /// previously-resolved schedule.
  Future<List<BranchAvailabilityEntity>?> _resolveCompanySchedule(
    BranchEntity branch,
  ) async {
    if (branch.availabilityMode != BranchAvailabilityMode.coreHours) {
      return null;
    }
    if (state.companySchedule != null) return state.companySchedule;

    final result = await _getCompanyScheduleUseCase(const NoParams()).run();
    return result.fold((_) => null, (schedule) => schedule);
  }
}
