import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/policies/branch_schedule_policy.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

class AddBranchDraftCubit extends Cubit<AddBranchDraft> {
  AddBranchDraftCubit() : super(const AddBranchDraft());

  /// Baseline the draft is compared against for the discard-unsaved-changes
  /// guard ([AddBranchDraft.hasChangesFrom]) — always the empty draft.
  static const _initial = AddBranchDraft();

  /// Whether the current draft differs from its baseline.
  bool get hasChanges => state.hasChangesFrom(_initial);

  void updateBasicInfo({
    String? branchName,
    String? phone,
  }) {
    emit(
      state.copyWith(
        branchName: branchName,
        phone: phone,
      ),
    );
  }

  void updateCity(CityEntity city) {
    emit(state.copyWith(selectedCity: () => city));
  }

  void updateBranchType(BranchType type) {
    emit(state.copyWith(branchType: type));
  }

  void updateLocation({
    required String? address,
    required LatLng? position,
  }) {
    emit(
      state.copyWith(
        branchAddress: () => address,
        pickedPosition: () => position,
      ),
    );
  }

  void updateManager(BranchManagerEntity? manager) {
    emit(state.copyWith(selectedManager: () => manager));
  }

  void updateScheduleMode(BranchScheduleMode mode) {
    emit(state.copyWith(scheduleMode: mode));
  }

  void updateCustomSchedule(List<BranchAvailabilityEntity> schedule) {
    emit(state.copyWith(customSchedule: schedule));
  }

  void initializeCustomSchedule(List<BranchAvailabilityEntity> schedule) {
    if (state.customSchedule.isNotEmpty) return;
    emit(state.copyWith(customSchedule: schedule));
  }

  /// Attempts to add a `[from, to)` slot to `dayId`'s custom schedule.
  ///
  /// Mirrors `EditWorkingHoursCubit.addSlot` (organization_settings) via
  /// the same shared [BranchSchedulePolicy]: on success the slot is merged
  /// into `dayId`'s existing group (or a new group is created if `dayId`
  /// has no slots yet) and the schedule is re-normalized; on rejection the
  /// schedule is left untouched and [ScheduleSlotRejection] is stashed so
  /// the UI can render an inline localized error.
  SlotValidation addScheduleSlot({
    required String dayId,
    required String from,
    required String to,
  }) {
    final result = BranchSchedulePolicy.upsertSlot(
      days: state.customSchedule,
      dayId: dayId,
      from: from,
      to: to,
    );

    if (!result.validation.isValid) {
      emit(
        state.copyWith(
          lastScheduleRejection: () => ScheduleSlotRejection(
            reason: result.validation.reason,
            dayId: dayId,
            from: from,
            to: to,
            conflict: result.validation.conflict,
          ),
        ),
      );
      return result.validation;
    }

    emit(
      state.copyWith(
        customSchedule: result.days,
        lastScheduleRejection: () => null,
      ),
    );
    return result.validation;
  }

  /// Deletes exactly one slot — `dayId`'s slot at `slotIndex` (that day's
  /// own chronological index). If that was the day's last slot, the
  /// (now-empty) day group is dropped from the custom schedule.
  void removeScheduleSlot(String dayId, int slotIndex) {
    final updated = BranchSchedulePolicy.removeSlot(
      days: state.customSchedule,
      dayId: dayId,
      slotIndex: slotIndex,
    );
    emit(
      state.copyWith(
        customSchedule: updated,
        lastScheduleRejection: () => null,
      ),
    );
  }

  /// Dismiss the inline schedule-rejection message (e.g. after the user
  /// edits the candidate values).
  void dismissScheduleRejection() =>
      emit(state.copyWith(lastScheduleRejection: () => null));

  void updateCoverage({
    required String? address,
    required LatLng? position,
    required double? radiusKm,
    required List<ServingArea> servingAreas,
  }) {
    emit(
      state.copyWith(
        branchAddress: () => address,
        pickedPosition: () => position,
        coverageRadiusKm: () => radiusKm,
        servingAreas: servingAreas,
      ),
    );
  }

  void updateServices(List<CatalogServiceSelection> services) {
    emit(state.copyWith(selectedServices: services));
  }

  void removeService(CatalogServiceSelection service) {
    emit(
      state.copyWith(
        selectedServices: state.selectedServices
            .where((s) => s.id != service.id)
            .toList(),
      ),
    );
  }

  void updateWorkers(List<WorkerEntity> workers) {
    emit(state.copyWith(selectedWorkers: workers));
  }

  void removeWorker(WorkerEntity worker) {
    emit(
      state.copyWith(
        selectedWorkers: state.selectedWorkers
            .where((w) => w.id != worker.id)
            .toList(),
      ),
    );
  }
}
