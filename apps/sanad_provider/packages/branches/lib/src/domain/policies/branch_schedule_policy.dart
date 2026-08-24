import 'package:branches/src/domain/entities/branch_availability_entity.dart';
import 'package:branches/src/domain/entities/branch_time_slot_entity.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:core/core.dart'
    show SlotValidationReason, WeeklyScheduleDay, WeeklySchedulePolicy;
import 'package:core/core.dart' as core show SlotValidation, WeeklyTimeSlot;

export 'package:core/core.dart' show SlotValidationReason;

/// Domain policy for per-branch working-hours validation and ordering.
///
/// Thin facade over the generic `WeeklySchedulePolicy` (`package:core`),
/// bound to this feature's own [BranchAvailabilityEntity]/
/// [BranchTimeSlotEntity] shapes and [BranchWeekdays] day order. The actual
/// overlap/grouping/sorting/upsert algorithm lives in one place —
/// `packages/core/lib/src/scheduling/weekly_schedule_policy.dart` — shared
/// with the provider-wide working-hours flow in `organization_settings`
/// (`WorkingHoursPolicy`), so the two features can never re-diverge on
/// scheduling behavior (SAN-573-class bugs: a newly-added slot rendering as
/// a duplicate day, or no overlap validation at all).
///
/// **Overlap rule (client-authoritative):**
/// Two slots `[a.from, a.to)` and `[b.from, b.to)` on the same day are
/// overlapping iff `a.from < b.to && b.from < a.to` — i.e. their open
/// intervals intersect. Adjacent slots where one ends exactly when the next
/// begins (e.g. `09:00-14:00` + `14:00-22:00`) are **valid**. A slot with
/// `from >= to` is rejected (no zero-duration, no overnight slots).
///
/// **Ordering:** weekdays follow [BranchWeekdays.all] (Saturday → Friday).
/// Slots within a day are sorted chronologically by `from`.
abstract final class BranchSchedulePolicy {
  BranchSchedulePolicy._();

  /// Validate a single candidate `[from, to)` slot in isolation. Rejects
  /// unparseable `HH:mm` or `from >= to`.
  static SlotValidation validateSlotTimes({
    required String from,
    required String to,
  }) => SlotValidation._fromCore(
    WeeklySchedulePolicy.validateSlotTimes(from: from, to: to),
  );

  /// Validate a candidate slot against [existingSlots] (that same day's
  /// current slots). `excludeIndex` is for editing an existing slot in
  /// place.
  static SlotValidation validateCandidateAgainst({
    required String from,
    required String to,
    required List<BranchTimeSlotEntity> existingSlots,
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
  static List<BranchTimeSlotEntity> sortSlotsChronologically(
    List<BranchTimeSlotEntity> slots,
  ) => WeeklySchedulePolicy.sortSlotsChronologically(
    slots.map(_slotToRecord).toList(),
  ).map(_slotFromRecord).toList();

  /// Canonical Saturday→Friday sort of a week's day entries — non-mutating.
  static List<BranchAvailabilityEntity> sortDaysCanonically(
    List<BranchAvailabilityEntity> days,
  ) => WeeklySchedulePolicy.sortDaysCanonically(
    days.map(_dayToRecord).toList(),
    canonicalOrder: BranchWeekdays.all,
  ).map(_dayFromRecord).toList();

  /// Single source of truth for turning any [availability] shape into the
  /// canonical one: same-day entries merged into one, slots sorted
  /// chronologically within each day, and days sorted Saturday→Friday.
  /// Non-mutating.
  static List<BranchAvailabilityEntity> normalizeAvailability(
    List<BranchAvailabilityEntity> availability,
  ) => WeeklySchedulePolicy.normalizeAvailability(
    availability.map(_dayToRecord).toList(),
    canonicalOrder: BranchWeekdays.all,
  ).map(_dayFromRecord).toList();

  /// Full-availability validation used defensively before save: returns the
  /// first `[day, conflict]` overlap discovered, or null when everything is
  /// clean.
  static AvailabilityConflict? findAvailabilityConflict(
    List<BranchAvailabilityEntity> availability,
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
  /// second, separate entry for the same day. The result is always
  /// re-normalized via [normalizeAvailability]. On rejection, [days] is
  /// returned unchanged.
  static ({List<BranchAvailabilityEntity> days, SlotValidation validation})
  upsertSlot({
    required List<BranchAvailabilityEntity> days,
    required String dayId,
    required String from,
    required String to,
  }) {
    final result = WeeklySchedulePolicy.upsertSlot(
      days: days.map(_dayToRecord).toList(),
      canonicalOrder: BranchWeekdays.all,
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
  /// own chronological index). If that was the day's last slot, the
  /// (now-empty) day group is dropped.
  static List<BranchAvailabilityEntity> removeSlot({
    required List<BranchAvailabilityEntity> days,
    required String dayId,
    required int slotIndex,
  }) => WeeklySchedulePolicy.removeSlot(
    days: days.map(_dayToRecord).toList(),
    dayId: dayId,
    slotIndex: slotIndex,
  ).map(_dayFromRecord).toList();

  static core.WeeklyTimeSlot _slotToRecord(BranchTimeSlotEntity slot) =>
      (from: slot.from, to: slot.to);

  static BranchTimeSlotEntity _slotFromRecord(core.WeeklyTimeSlot slot) =>
      BranchTimeSlotEntity(from: slot.from, to: slot.to);

  static WeeklyScheduleDay _dayToRecord(BranchAvailabilityEntity day) =>
      (day: day.day, slots: day.slots.map(_slotToRecord).toList());

  static BranchAvailabilityEntity _dayFromRecord(WeeklyScheduleDay day) =>
      BranchAvailabilityEntity(
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
            : BranchSchedulePolicy._slotFromRecord(source.conflict!),
      );

  final SlotValidationReason reason;

  /// The pre-existing slot the candidate collided with, when [reason] is
  /// [SlotValidationReason.overlapsExisting]. Null otherwise.
  final BranchTimeSlotEntity? conflict;

  bool get isValid => reason == SlotValidationReason.valid;
}

/// A same-day overlap found during full-availability validation.
class AvailabilityConflict {
  const AvailabilityConflict({
    required this.day,
    required this.first,
    required this.second,
  });

  /// Backend day id (e.g. `'SATURDAY'`) — see [BranchWeekdays].
  final String day;
  final BranchTimeSlotEntity first;
  final BranchTimeSlotEntity second;
}
