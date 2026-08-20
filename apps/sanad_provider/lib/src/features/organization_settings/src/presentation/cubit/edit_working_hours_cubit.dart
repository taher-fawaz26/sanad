import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';

/// The edit-working-hours sheet's draft entry list — a day can appear more
/// than once (split shifts, SAN-568), so this is a flat list, not a map.
///
/// [lastRejection] carries the most recent add-time validation result so the
/// sheet can surface an inline localized error next to the "Add day" form
/// without a separate error stream. `null` means "no error to show".
class EditWorkingHoursDraft extends Equatable {
  const EditWorkingHoursDraft({
    this.entries = const [],
    this.lastRejection,
  });

  final List<WorkingHoursEditEntry> entries;
  final SlotRejection? lastRejection;

  EditWorkingHoursDraft copyWith({
    List<WorkingHoursEditEntry>? entries,
    SlotRejection? lastRejection,
    bool clearLastRejection = false,
  }) => EditWorkingHoursDraft(
    entries: entries ?? this.entries,
    lastRejection: clearLastRejection
        ? null
        : (lastRejection ?? this.lastRejection),
  );

  @override
  List<Object?> get props => [entries, lastRejection];
}

/// A rejected add-slot attempt — enough context for the sheet to render a
/// localized error naming the day and (when applicable) the conflicting slot.
///
/// Kept in state instead of returned from `add()` so a single-user error
/// surface (a `BlocSelector`) can render it inline; no imperative
/// error-plumbing in the widget.
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

/// Owns the edit-working-hours sheet's local draft (add/delete entries
/// before Save).
///
/// Dependency-free and widget-scoped (seeded from the sheet's
/// `initialEntries`), so it's provided inline via `BlocProvider` at the
/// sheet, not registered in the service locator — same pattern as
/// `RegistrationDetailsCubit`.
///
/// Overlap and time-order checks all go through [WorkingHoursPolicy] —
/// the single source of truth for the rule — so this cubit stays a thin
/// draft container and the same policy is reused at save time.
class EditWorkingHoursCubit extends Cubit<EditWorkingHoursDraft> {
  EditWorkingHoursCubit({List<WorkingHoursEditEntry> initialEntries = const []})
    : super(EditWorkingHoursDraft(entries: List.of(initialEntries)));

  /// Attempts to append [entry]. Returns the [SlotValidation] result:
  ///  - on `.isValid`, the entry is appended and any prior rejection cleared;
  ///  - on rejection, the entry is **not** appended (non-destructive — the
  ///    existing valid draft is preserved) and [SlotRejection] is stashed
  ///    in state so the sheet can render an inline localized error.
  SlotValidation add(WorkingHoursEditEntry entry) {
    final sameDaySlots = <WorkingHoursSlotEntity>[
      for (final existing in state.entries)
        if (existing.dayId == entry.dayId)
          WorkingHoursSlotEntity(from: existing.from, to: existing.to),
    ];
    final validation = WorkingHoursPolicy.validateCandidateAgainst(
      from: entry.from,
      to: entry.to,
      existingSlots: sameDaySlots,
    );

    if (!validation.isValid) {
      emit(
        state.copyWith(
          lastRejection: SlotRejection(
            reason: validation.reason,
            dayId: entry.dayId,
            from: entry.from,
            to: entry.to,
            conflict: validation.conflict,
          ),
        ),
      );
      return validation;
    }

    emit(
      state.copyWith(
        entries: [...state.entries, entry],
        clearLastRejection: true,
      ),
    );
    return validation;
  }

  /// Delete by row index — a day can have multiple slots (SAN-568), so
  /// filtering by dayId would remove every split-shift for that day.
  ///
  /// Clears any pending rejection since it may no longer be relevant once
  /// the draft changes.
  void removeAt(int index) => emit(
    state.copyWith(
      entries: [...state.entries]..removeAt(index),
      clearLastRejection: true,
    ),
  );

  /// Dismiss the inline rejection message (e.g. after the user edits the
  /// candidate values).
  void dismissRejection() =>
      emit(state.copyWith(clearLastRejection: true));
}
