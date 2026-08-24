import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';

/// The edit-working-hours sheet's draft, grouped by day — the same shape as
/// [WorkingHoursDayEntity] the backend/bloc expect, always normalized
/// (`WorkingHoursPolicy.normalizeAvailability`: merged, sorted) after every
/// mutation so the UI never has to re-group at render time (SAN-573).
///
/// [lastRejection] carries the most recent add-time validation result so the
/// sheet can surface an inline localized error next to the "Add day" form
/// without a separate error stream. `null` means "no error to show".
class EditWorkingHoursDraft extends Equatable {
  const EditWorkingHoursDraft({
    this.days = const [],
    this.lastRejection,
  });

  final List<WorkingHoursDayEntity> days;
  final SlotRejection? lastRejection;

  EditWorkingHoursDraft copyWith({
    List<WorkingHoursDayEntity>? days,
    SlotRejection? lastRejection,
    bool clearLastRejection = false,
  }) => EditWorkingHoursDraft(
    days: days ?? this.days,
    lastRejection: clearLastRejection
        ? null
        : (lastRejection ?? this.lastRejection),
  );

  @override
  List<Object?> get props => [days, lastRejection];
}

/// A rejected add-slot attempt — enough context for the sheet to render a
/// localized error naming the day and (when applicable) the conflicting slot.
///
/// Kept in state instead of returned from [EditWorkingHoursCubit.addSlot] so
/// a single error surface (a `BlocSelector`) can render it inline; no
/// imperative error-plumbing in the widget.
class SlotRejection extends Equatable {
  const SlotRejection({
    required this.reason,
    required this.dayId,
    required this.from,
    required this.to,
    this.conflict,
  });

  final SlotValidationReason reason;
  final String dayId;
  final String from;
  final String to;
  final WorkingHoursSlotEntity? conflict;

  @override
  List<Object?> get props => [reason, dayId, from, to, conflict];
}

/// Owns the edit-working-hours sheet's local draft (add/delete slots before
/// Save), grouped by day.
///
/// Dependency-free and widget-scoped (seeded from the sheet's
/// `initialDays`), so it's provided inline via `BlocProvider` at the sheet,
/// not registered in the service locator — same pattern as
/// `RegistrationDetailsCubit`.
///
/// [addSlot] is an UPSERT at the day level: adding a slot for a day that
/// already has one or more slots merges into that same day's group — it
/// never creates a second, separate entry for the same day (the SAN-573 bug:
/// a newly-added Saturday slot rendering as its own trailing group instead of
/// joining the existing Saturday group). Every mutation re-normalizes via
/// [WorkingHoursPolicy.normalizeAvailability], so days stay Saturday→Friday
/// ordered and each day's slots stay chronological immediately — not only at
/// Save.
class EditWorkingHoursCubit extends Cubit<EditWorkingHoursDraft> {
  EditWorkingHoursCubit({List<WorkingHoursDayEntity> initialDays = const []})
    : super(
        EditWorkingHoursDraft(
          days: WorkingHoursPolicy.normalizeAvailability(initialDays),
        ),
      );

  /// Attempts to add a `[from, to)` slot to `dayId`. Returns the
  /// [SlotValidation] result:
  ///  - on `.isValid`, the slot is merged into `dayId`'s existing group (or a
  ///    new group is created if `dayId` has no slots yet), the draft is
  ///    re-normalized, and any prior rejection is cleared;
  ///  - on rejection, the draft is **not** modified (non-destructive — the
  ///    existing valid days/slots are preserved) and [SlotRejection] is
  ///    stashed in state so the sheet can render an inline localized error.
  SlotValidation addSlot({
    required String dayId,
    required String from,
    required String to,
  }) {
    final result = WorkingHoursPolicy.upsertSlot(
      days: state.days,
      dayId: dayId,
      from: from,
      to: to,
    );

    if (!result.validation.isValid) {
      emit(
        state.copyWith(
          lastRejection: SlotRejection(
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

    emit(state.copyWith(days: result.days, clearLastRejection: true));
    return result.validation;
  }

  /// Deletes exactly one slot — `dayId`'s slot at `slotIndex` (that day's
  /// own chronological index, not a flat cross-day index). Other slots on
  /// the same day, and every other day, are untouched. If that was the
  /// day's last slot, the (now-empty) day group is dropped from the draft.
  ///
  /// Clears any pending rejection since it may no longer be relevant once
  /// the draft changes.
  void removeSlot(String dayId, int slotIndex) {
    final updatedDays = WorkingHoursPolicy.removeSlot(
      days: state.days,
      dayId: dayId,
      slotIndex: slotIndex,
    );
    emit(state.copyWith(days: updatedDays, clearLastRejection: true));
  }

  /// Dismiss the inline rejection message (e.g. after the user edits the
  /// candidate values).
  void dismissRejection() => emit(state.copyWith(clearLastRejection: true));
}
