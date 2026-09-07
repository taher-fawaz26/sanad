import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:branches/src/domain/policies/branch_schedule_policy.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:maps/maps.dart';
import 'package:services/services.dart';
import 'package:workers/workers.dart';

part 'add_branch_draft_event.dart';

class AddBranchDraftBloc extends Bloc<AddBranchDraftEvent, AddBranchDraft> {
  AddBranchDraftBloc() : super(const AddBranchDraft()) {
    on<_AddBranchBasicInfoChanged>(_onBasicInfoChanged);
    on<_AddBranchTypeChanged>(_onTypeChanged);
    on<_AddBranchLocationUpdated>(_onLocationUpdated);
    on<_AddBranchManagerChanged>(_onManagerChanged);
    on<_AddBranchScheduleModeChanged>(_onScheduleModeChanged);
    on<_AddBranchCustomScheduleUpdated>(_onCustomScheduleUpdated);
    on<_AddBranchScheduleInitialized>(_onScheduleInitialized);
    on<_AddBranchCompanyHasWorkingHoursSet>(_onCompanyHasWorkingHoursSet);
    on<_AddBranchScheduleSlotApplied>(_onScheduleSlotApplied);
    on<_AddBranchScheduleSlotRemoved>(_onScheduleSlotRemoved);
    on<_AddBranchScheduleRejectionDismissed>(_onScheduleRejectionDismissed);
    on<_AddBranchCoverageUpdated>(_onCoverageUpdated);
    on<_AddBranchServicesChanged>(_onServicesChanged);
    on<_AddBranchServiceRemoved>(_onServiceRemoved);
    on<_AddBranchWorkersChanged>(_onWorkersChanged);
    on<_AddBranchWorkerRemoved>(_onWorkerRemoved);
  }

  /// Baseline the draft is compared against for the discard-unsaved-changes
  /// guard ([AddBranchDraft.hasChangesFrom]) — always the empty draft.
  static const _initial = AddBranchDraft();

  /// Whether the current draft differs from its baseline.
  bool get hasChanges => state.hasChangesFrom(_initial);

  // ---------------------------------------------------------------------------
  // Imperative helpers — kept so existing call sites don't need to be
  // rewritten. All state mutation still routes through event handlers below.
  // ---------------------------------------------------------------------------

  void updateBasicInfo({String? branchName, String? phone}) => add(
    _AddBranchBasicInfoChanged(branchName: branchName, phone: phone),
  );

  void updateBranchType(BranchType type) => add(_AddBranchTypeChanged(type));

  void updateLocation({
    required String? address,
    required LatLng? position,
    String? placeId,
  }) => add(
    _AddBranchLocationUpdated(
      address: address,
      position: position,
      placeId: placeId,
    ),
  );

  void updateManager(BranchManagerEntity? manager) =>
      add(_AddBranchManagerChanged(manager));

  void updateScheduleMode(BranchScheduleMode mode) =>
      add(_AddBranchScheduleModeChanged(mode));

  void updateCustomSchedule(List<BranchAvailabilityEntity> schedule) =>
      add(_AddBranchCustomScheduleUpdated(schedule));

  void initializeCustomSchedule(List<BranchAvailabilityEntity> schedule) =>
      add(_AddBranchScheduleInitialized(schedule));

  void setCompanyHasWorkingHours({required bool hasHours}) =>
      add(_AddBranchCompanyHasWorkingHoursSet(hasHours: hasHours));

  /// Attempts to add a `[from, to)` slot to `dayId`'s custom schedule.
  ///
  /// Runs the shared [BranchSchedulePolicy] synchronously so the widget
  /// callback (which returns [SlotValidation]) can react inline, then
  /// dispatches an event that folds the result into state.
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
    add(
      _AddBranchScheduleSlotApplied(
        dayId: dayId,
        from: from,
        to: to,
        updatedDays: result.days,
        validation: result.validation,
      ),
    );
    return result.validation;
  }

  void removeScheduleSlot(String dayId, int slotIndex) =>
      add(_AddBranchScheduleSlotRemoved(dayId: dayId, slotIndex: slotIndex));

  void dismissScheduleRejection() =>
      add(const _AddBranchScheduleRejectionDismissed());

  void updateCoverage({
    required String? address,
    required LatLng? position,
    required double? radiusKm,
    required List<ServingArea> servingAreas,
    String? placeId,
  }) => add(
    _AddBranchCoverageUpdated(
      address: address,
      position: position,
      radiusKm: radiusKm,
      servingAreas: servingAreas,
      placeId: placeId,
    ),
  );

  void updateServices(List<CatalogServiceSelection> services) =>
      add(_AddBranchServicesChanged(services));

  void removeService(CatalogServiceSelection service) =>
      add(_AddBranchServiceRemoved(service));

  void updateWorkers(List<WorkerEntity> workers) =>
      add(_AddBranchWorkersChanged(workers));

  void removeWorker(WorkerEntity worker) =>
      add(_AddBranchWorkerRemoved(worker));

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onBasicInfoChanged(
    _AddBranchBasicInfoChanged event,
    Emitter<AddBranchDraft> emit,
  ) => emit(
    state.copyWith(branchName: event.branchName, phone: event.phone),
  );

  void _onTypeChanged(
    _AddBranchTypeChanged event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(branchType: event.type));

  void _onLocationUpdated(
    _AddBranchLocationUpdated event,
    Emitter<AddBranchDraft> emit,
  ) => emit(
    state.copyWith(
      branchAddress: () => event.address,
      pickedPosition: () => event.position,
      locationPlaceId: () => event.placeId,
    ),
  );

  void _onManagerChanged(
    _AddBranchManagerChanged event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(selectedManager: () => event.manager));

  void _onScheduleModeChanged(
    _AddBranchScheduleModeChanged event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(scheduleMode: event.mode));

  void _onCustomScheduleUpdated(
    _AddBranchCustomScheduleUpdated event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(customSchedule: event.schedule));

  void _onScheduleInitialized(
    _AddBranchScheduleInitialized event,
    Emitter<AddBranchDraft> emit,
  ) {
    if (state.customSchedule.isNotEmpty) return;
    emit(state.copyWith(customSchedule: event.schedule));
  }

  void _onCompanyHasWorkingHoursSet(
    _AddBranchCompanyHasWorkingHoursSet event,
    Emitter<AddBranchDraft> emit,
  ) {
    if (state.companyHasWorkingHours == event.hasHours) return;
    emit(state.copyWith(companyHasWorkingHours: event.hasHours));
  }

  void _onScheduleSlotApplied(
    _AddBranchScheduleSlotApplied event,
    Emitter<AddBranchDraft> emit,
  ) {
    if (!event.validation.isValid) {
      emit(
        state.copyWith(
          lastScheduleRejection: () => ScheduleSlotRejection(
            reason: event.validation.reason,
            dayId: event.dayId,
            from: event.from,
            to: event.to,
            conflict: event.validation.conflict,
          ),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        customSchedule: event.updatedDays,
        lastScheduleRejection: () => null,
      ),
    );
  }

  void _onScheduleSlotRemoved(
    _AddBranchScheduleSlotRemoved event,
    Emitter<AddBranchDraft> emit,
  ) {
    final updated = BranchSchedulePolicy.removeSlot(
      days: state.customSchedule,
      dayId: event.dayId,
      slotIndex: event.slotIndex,
    );
    emit(
      state.copyWith(
        customSchedule: updated,
        lastScheduleRejection: () => null,
      ),
    );
  }

  void _onScheduleRejectionDismissed(
    _AddBranchScheduleRejectionDismissed event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(lastScheduleRejection: () => null));

  void _onCoverageUpdated(
    _AddBranchCoverageUpdated event,
    Emitter<AddBranchDraft> emit,
  ) => emit(
    state.copyWith(
      branchAddress: () => event.address,
      pickedPosition: () => event.position,
      coverageRadiusKm: () => event.radiusKm,
      servingAreas: event.servingAreas,
      locationPlaceId: event.placeId != null ? () => event.placeId : null,
    ),
  );

  void _onServicesChanged(
    _AddBranchServicesChanged event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(selectedServices: event.services));

  void _onServiceRemoved(
    _AddBranchServiceRemoved event,
    Emitter<AddBranchDraft> emit,
  ) => emit(
    state.copyWith(
      selectedServices: state.selectedServices
          .where((s) => s.id != event.service.id)
          .toList(),
    ),
  );

  void _onWorkersChanged(
    _AddBranchWorkersChanged event,
    Emitter<AddBranchDraft> emit,
  ) => emit(state.copyWith(selectedWorkers: event.workers));

  void _onWorkerRemoved(
    _AddBranchWorkerRemoved event,
    Emitter<AddBranchDraft> emit,
  ) => emit(
    state.copyWith(
      selectedWorkers: state.selectedWorkers
          .where((w) => w.id != event.worker.id)
          .toList(),
    ),
  );
}
