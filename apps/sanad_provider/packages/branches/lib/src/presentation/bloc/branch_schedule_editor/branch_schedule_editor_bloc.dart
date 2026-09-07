import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_schedule_mode.dart';
import 'package:branches/src/domain/policies/branch_schedule_policy.dart';
import 'package:branches/src/presentation/bloc/add_branch/add_branch_draft_state.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'branch_schedule_editor_event.dart';
part 'branch_schedule_editor_state.dart';

/// Owns the working-hours edit sheet's draft: mode (company vs custom),
/// custom-schedule slots, and the most recent add-slot rejection. Delegates
/// all validation to the shared [BranchSchedulePolicy] so this and the Add
/// Branch wizard's schedule step can never re-diverge.
class BranchScheduleEditorBloc
    extends Bloc<BranchScheduleEditorEvent, BranchScheduleEditorState> {
  BranchScheduleEditorBloc({
    required BranchAvailabilityMode initialMode,
    required List<BranchAvailabilityEntity> initialCustomSchedule,
    required List<BranchAvailabilityEntity> companySchedule,
  }) : super(
         BranchScheduleEditorState.initial(
           initialMode: initialMode,
           initialCustomSchedule: initialCustomSchedule,
           companySchedule: companySchedule,
         ),
       ) {
    on<BranchScheduleModeChanged>(_onModeChanged);
    on<BranchScheduleSlotApplied>(_onSlotApplied);
    on<BranchScheduleSlotRemoved>(_onSlotRemoved);
    on<BranchScheduleRejectionDismissed>(_onRejectionDismissed);
  }

  /// Widget-facing helper: evaluates the policy synchronously, dispatches the
  /// corresponding event to mutate state, and returns the [SlotValidation]
  /// so the calling widget (whose callback signature returns it) can react
  /// inline without needing to observe state.
  SlotValidation tryAddSlot({
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
      BranchScheduleSlotApplied(
        dayId: dayId,
        from: from,
        to: to,
        updatedDays: result.days,
        validation: result.validation,
      ),
    );
    return result.validation;
  }

  void _onModeChanged(
    BranchScheduleModeChanged event,
    Emitter<BranchScheduleEditorState> emit,
  ) {
    final newCustom =
        event.mode == BranchScheduleMode.custom && state.customSchedule.isEmpty
        ? List.of(state.companySchedule)
        : state.customSchedule;
    emit(
      state.copyWith(
        mode: event.mode,
        customSchedule: newCustom,
        clearRejection: true,
      ),
    );
  }

  void _onSlotApplied(
    BranchScheduleSlotApplied event,
    Emitter<BranchScheduleEditorState> emit,
  ) {
    if (!event.validation.isValid) {
      emit(
        state.copyWith(
          rejection: ScheduleSlotRejection(
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
        clearRejection: true,
      ),
    );
  }

  void _onSlotRemoved(
    BranchScheduleSlotRemoved event,
    Emitter<BranchScheduleEditorState> emit,
  ) {
    final updated = BranchSchedulePolicy.removeSlot(
      days: state.customSchedule,
      dayId: event.dayId,
      slotIndex: event.slotIndex,
    );
    emit(
      state.copyWith(customSchedule: updated, clearRejection: true),
    );
  }

  void _onRejectionDismissed(
    BranchScheduleRejectionDismissed event,
    Emitter<BranchScheduleEditorState> emit,
  ) => emit(state.copyWith(clearRejection: true));
}
