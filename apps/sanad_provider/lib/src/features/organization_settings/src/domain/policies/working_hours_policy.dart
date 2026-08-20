import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';

/// Domain policy for provider working-hours validation and ordering.
///
/// Single source of truth for the overlap rule and weekday/slot ordering —
/// the UI (edit sheet cubit, view mappers) and the save flow all consult
/// this policy instead of re-implementing the same logic in widgets. Keeps
/// the rule change-in-one-place if the backend contract ever tightens.
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

  /// Result of a candidate-slot validation check. Immutable value type.
  ///
  /// Callers pattern-match: `.valid` alone (drop the candidate through) vs.
  /// the specific rejection reason (surface a localized error).
  ///
  /// The specific reason drives which l10n key the UI shows — the policy
  /// itself never touches strings.
  static const _validationValid = SlotValidation._(SlotValidationReason.valid);

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
  }) {
    final f = _parseHhmm(from);
    final t = _parseHhmm(to);
    if (f == null || t == null) return _invalid(SlotValidationReason.malformed);
    if (f >= t) return _invalid(SlotValidationReason.endBeforeOrEqualStart);
    return _validationValid;
  }

  /// Validate a candidate slot for `day` against [existingSlots] (which
  /// must be that same day's current slots). Returns [SlotValidationReason
  /// .overlapsExisting] on the first conflict; the conflicting slot is
  /// exposed via [SlotValidation.conflict] so the UI can name it.
  ///
  /// `excludeIndex` is for the edit-existing-slot case: pass the index of
  /// the slot being edited so it isn't compared against itself.
  static SlotValidation validateCandidateAgainst({
    required String from,
    required String to,
    required List<WorkingHoursSlotEntity> existingSlots,
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

  /// True when two same-day slots share any interior time.
  /// Adjacent boundaries (`a.to == b.from`) are **not** an overlap.
  static bool _overlaps(String aFrom, String aTo, String bFrom, String bTo) {
    final af = _parseHhmm(aFrom);
    final at = _parseHhmm(aTo);
    final bf = _parseHhmm(bFrom);
    final bt = _parseHhmm(bTo);
    if (af == null || at == null || bf == null || bt == null) return false;
    return af < bt && bf < at;
  }

  /// Chronological (by `from`) sort of a day's slots — non-mutating.
  static List<WorkingHoursSlotEntity> sortSlotsChronologically(
    List<WorkingHoursSlotEntity> slots,
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

  /// Canonical Saturday→Friday sort of a week's day entries — non-mutating.
  /// Days not present in [WorkingHoursDayIds.all] are pushed to the end
  /// preserving their input order (defensive against unknown backend
  /// day codes).
  static List<WorkingHoursDayEntity> sortDaysCanonically(
    List<WorkingHoursDayEntity> days,
  ) {
    final indexOf = <String, int>{
      for (var i = 0; i < WorkingHoursDayIds.all.length; i++)
        WorkingHoursDayIds.all[i]: i,
    };
    final sorted = [...days]
      ..sort((a, b) {
        final ai = indexOf[a.day] ?? WorkingHoursDayIds.all.length;
        final bi = indexOf[b.day] ?? WorkingHoursDayIds.all.length;
        return ai.compareTo(bi);
      });
    return sorted;
  }

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

  static SlotValidation _invalid(SlotValidationReason reason) =>
      SlotValidation._(reason);

  /// HH:mm → minutes since midnight, or null if malformed.
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

/// Why a candidate slot was rejected — see [WorkingHoursPolicy].
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
