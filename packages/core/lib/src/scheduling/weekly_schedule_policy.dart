/// One `HH:mm` (24-hour) time range within a day.
typedef WeeklyTimeSlot = ({String from, String to});

/// One weekday's slots.
///
/// `day` is any caller-defined identifier string (e.g. `'Saturday'` or
/// `'SATURDAY'`) — the weekly-schedule policy never hardcodes a specific
/// casing or backend contract; callers pass their own `canonicalOrder`
/// wherever day order matters, so the same policy serves APIs that disagree
/// on day-code spelling.
typedef WeeklyScheduleDay = ({String day, List<WeeklyTimeSlot> slots});

/// Generic weekly-schedule domain policy — overlap validation, day/slot
/// ordering, day-level grouping, and upsert/remove semantics for a
/// once-per-week recurring schedule (working hours, business hours, etc).
///
/// Single source of truth shared by every feature that edits this kind of
/// schedule (e.g. organization working hours, per-branch working hours) —
/// each feature keeps its own persistence-shaped entity/DTO, but must route
/// every add/remove/validate/sort/group operation through this policy
/// instead of re-implementing it. That duplication is exactly what
/// previously let a newly-added slot for an existing day render as a
/// second, separate day entry instead of merging into the first, and let
/// one feature omit overlap validation entirely.
///
/// **Overlap rule (client-authoritative):**
/// Two slots `[a.from, a.to)` and `[b.from, b.to)` on the same day overlap
/// iff `a.from < b.to && b.from < a.to` — i.e. their open intervals
/// intersect. Adjacent slots where one ends exactly when the next begins
/// (e.g. `09:00-14:00` + `14:00-22:00`) are **valid**. A slot with
/// `from >= to` is rejected (no zero-duration, no overnight slots).
///
/// **Ordering:** slots within a day are sorted chronologically by `from`.
/// Days are sorted by the caller-supplied `canonicalOrder`; unrecognized day
/// codes are pushed to the end, preserving their relative input order.
abstract final class WeeklySchedulePolicy {
  WeeklySchedulePolicy._();

  static const _validationValid = SlotValidation._(SlotValidationReason.valid);

  /// Validate a single candidate `[from, to)` slot in isolation
  /// (independent of any existing slots). Rejects unparseable `HH:mm` or
  /// `from >= to`.
  ///
  /// Use this to gate an "Add" button before comparing against existing
  /// slots via [validateCandidateAgainst].
  static SlotValidation validateSlotTimes({
    required String from,
    required String to,
  }) {
    final f = _parseHhmm(from);
    final t = _parseHhmm(to);
    if (f == null || t == null) {
      return const SlotValidation._(SlotValidationReason.malformed);
    }
    if (f >= t) {
      return const SlotValidation._(SlotValidationReason.endBeforeOrEqualStart);
    }
    return _validationValid;
  }

  /// Validate a candidate slot against [existingSlots] (that same day's
  /// current slots). Returns [SlotValidationReason.overlapsExisting] on the
  /// first conflict, exposed via [SlotValidation.conflict] so the UI can
  /// name it.
  ///
  /// `excludeIndex` is for editing an existing slot in place — pass its
  /// index so it isn't compared against itself.
  static SlotValidation validateCandidateAgainst({
    required String from,
    required String to,
    required List<WeeklyTimeSlot> existingSlots,
    int? excludeIndex,
  }) {
    final base = validateSlotTimes(from: from, to: to);
    if (!base.isValid) return base;

    for (var i = 0; i < existingSlots.length; i++) {
      if (i == excludeIndex) continue;
      final other = existingSlots[i];
      if (_overlaps(from, to, other.from, other.to)) {
        return SlotValidation._(
          SlotValidationReason.overlapsExisting,
          conflict: other,
        );
      }
    }
    return _validationValid;
  }

  /// True when two same-day slots share any interior time. Adjacent
  /// boundaries (`a.to == b.from`) are **not** an overlap.
  static bool _overlaps(String aFrom, String aTo, String bFrom, String bTo) {
    final af = _parseHhmm(aFrom);
    final at = _parseHhmm(aTo);
    final bf = _parseHhmm(bFrom);
    final bt = _parseHhmm(bTo);
    if (af == null || at == null || bf == null || bt == null) return false;
    return af < bt && bf < at;
  }

  /// Chronological (by `from`) sort of a day's slots — non-mutating.
  static List<WeeklyTimeSlot> sortSlotsChronologically(
    List<WeeklyTimeSlot> slots,
  ) {
    final sorted = [...slots]
      ..sort((a, b) {
        final af = _parseHhmm(a.from) ?? 0;
        final bf = _parseHhmm(b.from) ?? 0;
        final byFrom = af.compareTo(bf);
        if (byFrom != 0) return byFrom;
        final at = _parseHhmm(a.to) ?? 0;
        final bt = _parseHhmm(b.to) ?? 0;
        return at.compareTo(bt);
      });
    return sorted;
  }

  /// Canonical sort of a week's day entries by [canonicalOrder] —
  /// non-mutating. Days not present in [canonicalOrder] are pushed to the
  /// end, preserving their input order (defensive against unknown backend
  /// day codes).
  static List<WeeklyScheduleDay> sortDaysCanonically(
    List<WeeklyScheduleDay> days, {
    required List<String> canonicalOrder,
  }) {
    final indexOf = <String, int>{
      for (var i = 0; i < canonicalOrder.length; i++) canonicalOrder[i]: i,
    };
    final sorted = [...days]
      ..sort((a, b) {
        final ai = indexOf[a.day] ?? canonicalOrder.length;
        final bi = indexOf[b.day] ?? canonicalOrder.length;
        return ai.compareTo(bi);
      });
    return sorted;
  }

  /// Single source of truth for turning any [availability] shape into the
  /// canonical one: same-day entries merged into one, slots sorted
  /// chronologically within each day, and days sorted by [canonicalOrder].
  /// Non-mutating.
  ///
  /// Every mutation point (initial load, add-slot, delete-slot, and the
  /// defensive re-check at save) should route through this rather than
  /// re-implementing grouping/sorting locally.
  static List<WeeklyScheduleDay> normalizeAvailability(
    List<WeeklyScheduleDay> availability, {
    required List<String> canonicalOrder,
  }) {
    final slotsByDay = <String, List<WeeklyTimeSlot>>{};
    for (final day in availability) {
      (slotsByDay[day.day] ??= <WeeklyTimeSlot>[]).addAll(day.slots);
    }
    final merged = [
      for (final entry in slotsByDay.entries)
        (day: entry.key, slots: sortSlotsChronologically(entry.value)),
    ];
    return sortDaysCanonically(merged, canonicalOrder: canonicalOrder);
  }

  /// Full-availability validation used defensively before save: returns the
  /// first `[day, conflict]` overlap discovered, or null when everything is
  /// clean. Slot order within each day does not matter here.
  ///
  /// This is the last line of defence — normal user interaction should have
  /// already prevented invalid state via [validateCandidateAgainst], so a
  /// non-null result at save time indicates a client bug or a stale draft.
  static AvailabilityConflict? findAvailabilityConflict(
    List<WeeklyScheduleDay> availability,
  ) {
    for (final day in availability) {
      for (var i = 0; i < day.slots.length; i++) {
        for (var j = i + 1; j < day.slots.length; j++) {
          final a = day.slots[i];
          final b = day.slots[j];
          if (_overlaps(a.from, a.to, b.from, b.to)) {
            return AvailabilityConflict(day: day.day, first: a, second: b);
          }
        }
      }
    }
    return null;
  }

  /// Upsert at the day level: validates the candidate `[from, to)` slot for
  /// `dayId` against that day's current slots (if any). On success, merges
  /// it into `dayId`'s existing group — or creates a new single-slot group
  /// if `dayId` has no slots yet — and re-normalizes via
  /// [normalizeAvailability], so the result is never a second, separate
  /// entry for a day that already exists. On rejection, [days] is returned
  /// unchanged (non-destructive).
  static ({List<WeeklyScheduleDay> days, SlotValidation validation})
  upsertSlot({
    required List<WeeklyScheduleDay> days,
    required List<String> canonicalOrder,
    required String dayId,
    required String from,
    required String to,
  }) {
    WeeklyScheduleDay? existingDay;
    for (final day in days) {
      if (day.day == dayId) {
        existingDay = day;
        break;
      }
    }

    final validation = validateCandidateAgainst(
      from: from,
      to: to,
      existingSlots: existingDay?.slots ?? const [],
    );
    if (!validation.isValid) return (days: days, validation: validation);

    final newSlot = (from: from, to: to);
    final updated = [
      for (final day in days)
        if (day.day == dayId)
          (day: day.day, slots: [...day.slots, newSlot])
        else
          day,
      if (existingDay == null) (day: dayId, slots: [newSlot]),
    ];

    return (
      days: normalizeAvailability(updated, canonicalOrder: canonicalOrder),
      validation: validation,
    );
  }

  /// Deletes exactly one slot — `dayId`'s slot at `slotIndex` (that day's
  /// own chronological index, not a flat cross-day index). If that was the
  /// day's last slot, the (now-empty) day group is dropped.
  static List<WeeklyScheduleDay> removeSlot({
    required List<WeeklyScheduleDay> days,
    required String dayId,
    required int slotIndex,
  }) {
    final updated = <WeeklyScheduleDay>[];
    for (final day in days) {
      if (day.day != dayId) {
        updated.add(day);
        continue;
      }
      final remainingSlots = [...day.slots]..removeAt(slotIndex);
      if (remainingSlots.isNotEmpty) {
        updated.add((day: day.day, slots: remainingSlots));
      }
    }
    return updated;
  }

  /// `HH:mm` → minutes since midnight, or null if malformed.
  static int? _parseHhmm(String time) {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  }
}

/// Why a candidate slot was rejected — see [WeeklySchedulePolicy].
enum SlotValidationReason {
  valid,
  malformed,
  endBeforeOrEqualStart,
  overlapsExisting,
}

/// Result of a slot validation check.
class SlotValidation {
  const SlotValidation._(this.reason, {this.conflict});

  final SlotValidationReason reason;

  /// The pre-existing slot the candidate collided with, when [reason] is
  /// [SlotValidationReason.overlapsExisting]. Null otherwise.
  final WeeklyTimeSlot? conflict;

  bool get isValid => reason == SlotValidationReason.valid;
}

/// A same-day overlap found during full-availability validation.
class AvailabilityConflict {
  const AvailabilityConflict({
    required this.day,
    required this.first,
    required this.second,
  });

  final String day;
  final WeeklyTimeSlot first;
  final WeeklyTimeSlot second;
}
