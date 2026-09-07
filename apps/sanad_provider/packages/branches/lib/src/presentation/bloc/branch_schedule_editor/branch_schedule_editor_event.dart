part of 'branch_schedule_editor_bloc.dart';

sealed class BranchScheduleEditorEvent extends Equatable {
  const BranchScheduleEditorEvent();

  @override
  List<Object?> get props => [];
}

final class BranchScheduleModeChanged extends BranchScheduleEditorEvent {
  const BranchScheduleModeChanged(this.mode);

  final BranchScheduleMode mode;

  @override
  List<Object?> get props => [mode];
}

/// Emitted by [BranchScheduleEditorBloc.tryAddSlot] with a pre-computed
/// policy result — the bloc's handler folds it into state (either updating
/// `customSchedule` on success, or stashing a `rejection` on failure).
final class BranchScheduleSlotApplied extends BranchScheduleEditorEvent {
  const BranchScheduleSlotApplied({
    required this.dayId,
    required this.from,
    required this.to,
    required this.updatedDays,
    required this.validation,
  });

  final String dayId;
  final String from;
  final String to;
  final List<BranchAvailabilityEntity> updatedDays;
  final SlotValidation validation;

  @override
  List<Object?> get props => [dayId, from, to, updatedDays, validation];
}

final class BranchScheduleSlotRemoved extends BranchScheduleEditorEvent {
  const BranchScheduleSlotRemoved({
    required this.dayId,
    required this.slotIndex,
  });

  final String dayId;
  final int slotIndex;

  @override
  List<Object?> get props => [dayId, slotIndex];
}

final class BranchScheduleRejectionDismissed extends BranchScheduleEditorEvent {
  const BranchScheduleRejectionDismissed();
}
