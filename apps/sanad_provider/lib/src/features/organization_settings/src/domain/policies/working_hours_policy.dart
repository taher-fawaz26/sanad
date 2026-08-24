import 'package:core/core.dart'
    show SlotValidationReason, WeeklyScheduleDay, WeeklySchedulePolicy;
import 'package:core/core.dart' as core show SlotValidation, WeeklyTimeSlot;
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';

export 'package:core/core.dart' show SlotValidationReason;

/// Domain policy for provider working-hours validation and ordering.
///
/// Thin facade over the generic `WeeklySchedulePolicy` (`package:core`),
/// bound to this feature's own [WorkingHoursDayEntity]/
/// [WorkingHoursSlotEntity] shapes and [WorkingHoursDayIds] day order. The
/// actual overlap/grouping/sorting/upsert algorithm lives in one place —
/// `packages/core/lib/src/scheduling/weekly_schedule_policy.dart` — shared
/// with the per-branch working-hours flow in the `branches` package
/// (`BranchSchedulePolicy`), so the two features can never re-diverge on
/// scheduling behavior. This facade exists so every call site here keeps
/// working with [WorkingHoursDayEntity]/[WorkingHoursSlotEntity] rather than
/// the generic record shape.
///
/// **Overlap rule (client-authoritative):**
/// Two slots `[a.from, a.to)` and `[b.from, b.to)` on the same day are
/// overlapping iff `a.from < b.to && b.from < a.to` — i.e. their open
/// intervals intersect. Adjacent slots where one ends exactly when the next
/// begins (e.g. `09:00-14:00` + `14:00-22:00`) are **valid**. This matches
/// the shared "closed/open interval" convention already used elsewhere in
/// the app and does not introduce overnight slots (a slot with
/// `from >= to` is rejected).
///
/// **Ordering:**
/// Weekdays follow [WorkingHoursDayIds.all] (Saturday → Friday). Slots
/// within a day are sorted chronologically by `from`. Both are stable when
/// the input is already ordered, and neither mutates the input.
abstract final class WorkingHoursPolicy {
  WorkingHoursPolicy._();

  /// Validate a single candidate `[from, to)` slot in isolation
  /// (independent of any existing slots). Rejects:
  /// - unparseable HH:mm
  /// - `from >= to` (no zero-duration, no overnight)
  ///
  /// Use this to gate the "Add" button in a picker before comparing against
  /// existing slots for [validateCandidateAgainst].
  static SlotValidation validateSlotTimes({
    required String from,
    required String to,
  }) => SlotValidation._fromCore(
    WeeklySchedulePolicy.validateSlotTimes(from: from, to: to),
  );

  /// Validate a candidate slot for `day` against [existingSlots] (which
  /// must be that same day's current slots). Returns
  /// [SlotValidationReason.overlapsExisting] on the first conflict; the
  /// conflicting slot is exposed via [SlotValidation.conflict] so the UI can
  /// name it.
  ///
  /// `excludeIndex` is for the edit-existing-slot case: pass the index of
  /// the slot being edited so it isn't compared against itself.
  static SlotValidation validateCandidateAgainst({
    required String from,
    required String to,
    required List<WorkingHoursSlotEntity> existingSlots,
    int? excludeIndex,
  }) => SlotValidation._fromCore(
    WeeklySchedulePolicy.validateCandidateAgainst(
      from: from,
      to: to,
      existingSlots: existingSlots.map(_slotToRecord).toList(),
      excludeIndex: excludeIndex,
    ),
  );

  /// Chronological (by `from`) sort of a day's slots — non-mutating.
  static List<WorkingHoursSlotEntity> sortSlotsChronologically(
    List<WorkingHoursSlotEntity> slots,
  ) => WeeklySchedulePolicy.sortSlotsChronologically(
    slots.map(_slotToRecord).toList(),
  ).map(_slotFromRecord).toList();

  /// Canonical Saturday→Friday sort of a week's day entries — non-mutating.
  /// Days not present in [WorkingHoursDayIds.all] are pushed to the end
  /// preserving their input order (defensive against unknown backend
  /// day codes).
  static List<WorkingHoursDayEntity> sortDaysCanonically(
    List<WorkingHoursDayEntity> days,
  ) => WeeklySchedulePolicy.sortDaysCanonically(
    days.map(_dayToRecord).toList(),
    canonicalOrder: WorkingHoursDayIds.all,
  ).map(_dayFromRecord).toList();

  /// Single source of truth for turning any [availability] shape into the
  /// canonical one: same-day entries merged into one, slots sorted
  /// chronologically within each day, and days sorted Saturday→Friday.
  /// Non-mutating.
  ///
  /// Every mutation point (initial load, add-slot, delete-slot, and the
  /// defensive re-check at save) should route through this rather than
  /// re-implementing grouping/sorting locally — that duplication is exactly
  /// what let a newly-added slot for an existing day render as a second,
  /// separate day entry instead of merging into the first (SAN-573).
  static List<WorkingHoursDayEntity> normalizeAvailability(
    List<WorkingHoursDayEntity> availability,
  ) => WeeklySchedulePolicy.normalizeAvailability(
    availability.map(_dayToRecord).toList(),
    canonicalOrder: WorkingHoursDayIds.all,
  ).map(_dayFromRecord).toList();

  /// Full-availability validation used defensively before save: returns the
  /// first `[day, conflict]` overlap discovered, or null when everything is
  /// clean. Slot order within each day does not matter here.
  ///
  /// This is the last line of defence — normal user interaction should have
  /// already prevented invalid state via [validateCandidateAgainst], so a
  /// non-null result at save time indicates a client bug or a stale draft.
  static AvailabilityConflict? findAvailabilityConflict(
    List<WorkingHoursDayEntity> availability,
  ) {
    final conflict = WeeklySchedulePolicy.findAvailabilityConflict(
      availability.map(_dayToRecord).toList(),
    );
    if (conflict == null) return null;
    return AvailabilityConflict(
      day: conflict.day,
      first: _slotFromRecord(conflict.first),
      second: _slotFromRecord(conflict.second),
    );
  }

  /// Upsert at the day level: adding a slot for a day that already has one
  /// or more slots merges into that same day's group — it never creates a
  /// second, separate entry for the same day (SAN-573). The result is
  /// always re-normalized via [normalizeAvailability]. On rejection, [days]
  /// is returned unchanged.
  static ({List<WorkingHoursDayEntity> days, SlotValidation validation})
  upsertSlot({
    required List<WorkingHoursDayEntity> days,
    required String dayId,
    required String from,
    required String to,
  }) {
    final result = WeeklySchedulePolicy.upsertSlot(
      days: days.map(_dayToRecord).toList(),
      canonicalOrder: WorkingHoursDayIds.all,
      dayId: dayId,
      from: from,
      to: to,
    );
    final validation = SlotValidation._fromCore(result.validation);
    if (!validation.isValid) return (days: days, validation: validation);
    return (
      days: result.days.map(_dayFromRecord).toList(),
      validation: validation,
    );
  }

  /// Deletes exactly one slot — `dayId`'s slot at `slotIndex` (that day's
  /// own chronological index, not a flat cross-day index). If that was the
  /// day's last slot, the (now-empty) day group is dropped.
  static List<WorkingHoursDayEntity> removeSlot({
    required List<WorkingHoursDayEntity> days,
    required String dayId,
    required int slotIndex,
  }) => WeeklySchedulePolicy.removeSlot(
    days: days.map(_dayToRecord).toList(),
    dayId: dayId,
    slotIndex: slotIndex,
  ).map(_dayFromRecord).toList();

  static core.WeeklyTimeSlot _slotToRecord(WorkingHoursSlotEntity slot) =>
      (from: slot.from, to: slot.to);

  static WorkingHoursSlotEntity _slotFromRecord(core.WeeklyTimeSlot slot) =>
      WorkingHoursSlotEntity(from: slot.from, to: slot.to);

  static WeeklyScheduleDay _dayToRecord(WorkingHoursDayEntity day) =>
      (day: day.day, slots: day.slots.map(_slotToRecord).toList());

  static WorkingHoursDayEntity _dayFromRecord(WeeklyScheduleDay day) =>
      WorkingHoursDayEntity(
        day: day.day,
        slots: day.slots.map(_slotFromRecord).toList(),
      );
}

/// Result of a slot validation check.
class SlotValidation {
  const SlotValidation._(this.reason, {this.conflict});

  factory SlotValidation._fromCore(core.SlotValidation source) =>
      SlotValidation._(
        source.reason,
        conflict: source.conflict == null
            ? null
            : WorkingHoursPolicy._slotFromRecord(source.conflict!),
      );

  final SlotValidationReason reason;

  /// The pre-existing slot the candidate collided with, when
  /// [reason] is [SlotValidationReason.overlapsExisting]. Null otherwise.
  final WorkingHoursSlotEntity? conflict;

  bool get isValid => reason == SlotValidationReason.valid;
}

/// A same-day overlap found during full-availability validation.
class AvailabilityConflict {
  const AvailabilityConflict({
    required this.day,
    required this.first,
    required this.second,
  });

  /// Backend day id (e.g. `'Saturday'`) — see [WorkingHoursDayIds].
  final String day;
  final WorkingHoursSlotEntity first;
  final WorkingHoursSlotEntity second;
}
