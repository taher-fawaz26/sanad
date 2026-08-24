import 'package:core/src/scheduling/weekly_schedule_policy.dart';
import 'package:flutter_test/flutter_test.dart';

WeeklyTimeSlot _slot(String from, String to) => (from: from, to: to);

const _order = [
  'Saturday',
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
];

void main() {
  group('WeeklySchedulePolicy.validateSlotTimes', () {
    test('valid slot passes', () {
      expect(
        WeeklySchedulePolicy.validateSlotTimes(
          from: '09:00',
          to: '14:00',
        ).isValid,
        isTrue,
      );
    });

    test('start == end is rejected (zero-duration)', () {
      final result = WeeklySchedulePolicy.validateSlotTimes(
        from: '09:00',
        to: '09:00',
      );
      expect(result.reason, SlotValidationReason.endBeforeOrEqualStart);
    });

    test('start > end is rejected (no overnight support)', () {
      final result = WeeklySchedulePolicy.validateSlotTimes(
        from: '18:00',
        to: '02:00',
      );
      expect(result.reason, SlotValidationReason.endBeforeOrEqualStart);
    });

    test('malformed time rejected', () {
      expect(
        WeeklySchedulePolicy.validateSlotTimes(
          from: 'nope',
          to: '14:00',
        ).reason,
        SlotValidationReason.malformed,
      );
      expect(
        WeeklySchedulePolicy.validateSlotTimes(
          from: '25:00',
          to: '26:00',
        ).reason,
        SlotValidationReason.malformed,
      );
    });
  });

  group('WeeklySchedulePolicy.validateCandidateAgainst', () {
    final existing = [_slot('09:00', '14:00')];

    test('exact duplicate rejected', () {
      final result = WeeklySchedulePolicy.validateCandidateAgainst(
        from: '09:00',
        to: '14:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
      expect(result.conflict, existing.first);
    });

    test('partial overlap rejected', () {
      final result = WeeklySchedulePolicy.validateCandidateAgainst(
        from: '13:00',
        to: '15:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
    });

    test('contained slot rejected', () {
      final result = WeeklySchedulePolicy.validateCandidateAgainst(
        from: '10:00',
        to: '12:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
    });

    test('containing slot rejected', () {
      final result = WeeklySchedulePolicy.validateCandidateAgainst(
        from: '08:00',
        to: '15:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
    });

    test('boundary-touching slot (adjacent) is VALID', () {
      expect(
        WeeklySchedulePolicy.validateCandidateAgainst(
          from: '14:00',
          to: '22:00',
          existingSlots: existing,
        ).isValid,
        isTrue,
      );
      expect(
        WeeklySchedulePolicy.validateCandidateAgainst(
          from: '08:00',
          to: '09:00',
          existingSlots: existing,
        ).isValid,
        isTrue,
      );
    });

    test('non-overlapping slot before existing is valid', () {
      expect(
        WeeklySchedulePolicy.validateCandidateAgainst(
          from: '06:00',
          to: '08:00',
          existingSlots: existing,
        ).isValid,
        isTrue,
      );
    });

    test('excludeIndex allows editing a slot with its own current range', () {
      final result = WeeklySchedulePolicy.validateCandidateAgainst(
        from: '09:00',
        to: '14:00',
        existingSlots: existing,
        excludeIndex: 0,
      );
      expect(result.isValid, isTrue);
    });

    test(
      'excludeIndex still catches overlap with a DIFFERENT existing slot',
      () {
        final result = WeeklySchedulePolicy.validateCandidateAgainst(
          from: '15:00',
          to: '17:00',
          existingSlots: [_slot('09:00', '14:00'), _slot('16:00', '18:00')],
          excludeIndex: 0,
        );
        expect(result.reason, SlotValidationReason.overlapsExisting);
      },
    );

    test('candidate with start >= end is rejected before overlap check', () {
      final result = WeeklySchedulePolicy.validateCandidateAgainst(
        from: '14:00',
        to: '09:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.endBeforeOrEqualStart);
    });
  });

  group('WeeklySchedulePolicy.sortSlotsChronologically', () {
    test('sorts by from time', () {
      final result = WeeklySchedulePolicy.sortSlotsChronologically([
        _slot('16:00', '22:00'),
        _slot('09:00', '15:00'),
      ]);
      expect(result.first.from, '09:00');
      expect(result.last.from, '16:00');
    });

    test('input is not mutated', () {
      final input = [_slot('16:00', '22:00'), _slot('09:00', '15:00')];
      WeeklySchedulePolicy.sortSlotsChronologically(input);
      expect(input.first.from, '16:00');
    });
  });

  group('WeeklySchedulePolicy.sortDaysCanonically', () {
    test('always Saturday → Friday regardless of input order', () {
      final result = WeeklySchedulePolicy.sortDaysCanonically(
        [
          (day: 'Friday', slots: const <WeeklyTimeSlot>[]),
          (day: 'Monday', slots: const <WeeklyTimeSlot>[]),
          (day: 'Saturday', slots: const <WeeklyTimeSlot>[]),
        ],
        canonicalOrder: _order,
      );
      expect(result.map((d) => d.day).toList(), [
        'Saturday',
        'Monday',
        'Friday',
      ]);
    });

    test('unknown day codes pushed to end (defensive)', () {
      final result = WeeklySchedulePolicy.sortDaysCanonically(
        [
          (day: 'BOGUS', slots: const <WeeklyTimeSlot>[]),
          (day: 'Saturday', slots: const <WeeklyTimeSlot>[]),
        ],
        canonicalOrder: _order,
      );
      expect(result.first.day, 'Saturday');
      expect(result.last.day, 'BOGUS');
    });

    test('is agnostic to day-code casing — caller supplies its own order', () {
      final result = WeeklySchedulePolicy.sortDaysCanonically(
        [
          (day: 'FRIDAY', slots: const <WeeklyTimeSlot>[]),
          (day: 'SATURDAY', slots: const <WeeklyTimeSlot>[]),
        ],
        canonicalOrder: const [
          'SATURDAY',
          'SUNDAY',
          'MONDAY',
          'TUESDAY',
          'WEDNESDAY',
          'THURSDAY',
          'FRIDAY',
        ],
      );
      expect(result.map((d) => d.day).toList(), ['SATURDAY', 'FRIDAY']);
    });
  });

  group('WeeklySchedulePolicy.normalizeAvailability', () {
    test(
      'merges two separate entries for the SAME day into one group '
      '(a newly-added slot must never render as a second, separate day '
      'entry)',
      () {
        final result = WeeklySchedulePolicy.normalizeAvailability(
          [
            (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
            (day: 'Saturday', slots: [_slot('14:00', '18:00')]),
          ],
          canonicalOrder: _order,
        );
        expect(result, hasLength(1));
        expect(result.single.slots, hasLength(2));
      },
    );

    test(
      'adding a third slot to an already-multi-slot day keeps one group',
      () {
        final result = WeeklySchedulePolicy.normalizeAvailability(
          [
            (
              day: 'Saturday',
              slots: [_slot('09:00', '14:00'), _slot('14:05', '18:00')],
            ),
            (day: 'Saturday', slots: [_slot('18:30', '22:00')]),
          ],
          canonicalOrder: _order,
        );
        expect(result, hasLength(1));
        expect(result.single.slots, hasLength(3));
        expect(result.single.slots.map((s) => s.from).toList(), [
          '09:00',
          '14:05',
          '18:30',
        ]);
      },
    );

    test('sorts days Saturday → Friday regardless of input order', () {
      final result = WeeklySchedulePolicy.normalizeAvailability(
        [
          (day: 'Friday', slots: [_slot('10:00', '14:00')]),
          (day: 'Saturday', slots: [_slot('10:00', '14:00')]),
        ],
        canonicalOrder: _order,
      );
      expect(result.map((d) => d.day).toList(), ['Saturday', 'Friday']);
    });

    test('sorts slots chronologically within each merged day', () {
      final result = WeeklySchedulePolicy.normalizeAvailability(
        [
          (day: 'Saturday', slots: [_slot('16:00', '22:00')]),
          (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
        ],
        canonicalOrder: _order,
      );
      expect(result.single.slots[0].from, '09:00');
      expect(result.single.slots[1].from, '16:00');
    });

    test('empty availability yields an empty list', () {
      expect(
        WeeklySchedulePolicy.normalizeAvailability(
          const [],
          canonicalOrder: _order,
        ),
        isEmpty,
      );
    });

    test('does not mutate the input list', () {
      final input = [
        (day: 'Friday', slots: [_slot('10:00', '14:00')]),
      ];
      WeeklySchedulePolicy.normalizeAvailability(
        input,
        canonicalOrder: _order,
      );
      expect(input.single.day, 'Friday');
    });
  });

  group('WeeklySchedulePolicy.findAvailabilityConflict', () {
    test('clean availability returns null', () {
      final result = WeeklySchedulePolicy.findAvailabilityConflict([
        (
          day: 'Saturday',
          slots: [_slot('09:00', '14:00'), _slot('15:00', '18:00')],
        ),
        (day: 'Sunday', slots: [_slot('10:00', '16:00')]),
      ]);
      expect(result, isNull);
    });

    test('adjacent slots on same day treated as valid (no conflict)', () {
      final result = WeeklySchedulePolicy.findAvailabilityConflict([
        (
          day: 'Saturday',
          slots: [_slot('09:00', '14:00'), _slot('14:00', '22:00')],
        ),
      ]);
      expect(result, isNull);
    });

    test('same-day overlap surfaced with both slots', () {
      final a = _slot('09:00', '14:00');
      final b = _slot('13:00', '15:00');
      final result = WeeklySchedulePolicy.findAvailabilityConflict([
        (day: 'Saturday', slots: [a, b]),
      ]);
      expect(result, isNotNull);
      expect(result!.day, 'Saturday');
      expect(result.first, a);
      expect(result.second, b);
    });

    test('different-day overlap allowed (not a conflict)', () {
      final result = WeeklySchedulePolicy.findAvailabilityConflict([
        (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
        (day: 'Sunday', slots: [_slot('09:00', '14:00')]),
      ]);
      expect(result, isNull);
    });
  });

  group('WeeklySchedulePolicy.upsertSlot', () {
    test('adding a slot to a brand-new day creates a single-slot group', () {
      final result = WeeklySchedulePolicy.upsertSlot(
        days: const [],
        canonicalOrder: _order,
        dayId: 'Saturday',
        from: '09:00',
        to: '14:00',
      );
      expect(result.validation.isValid, isTrue);
      expect(result.days, hasLength(1));
      expect(result.days.single.slots, hasLength(1));
    });

    test(
      'adding a slot to a day that already has one merges into that '
      "day's existing group instead of creating a second entry",
      () {
        final result = WeeklySchedulePolicy.upsertSlot(
          days: [
            (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
          ],
          canonicalOrder: _order,
          dayId: 'Saturday',
          from: '14:05',
          to: '18:00',
        );
        expect(result.validation.isValid, isTrue);
        expect(result.days, hasLength(1));
        expect(result.days.single.slots, hasLength(2));
      },
    );

    test('a new day is inserted in canonical position, not appended', () {
      final result = WeeklySchedulePolicy.upsertSlot(
        days: [
          (day: 'Friday', slots: [_slot('10:00', '12:00')]),
        ],
        canonicalOrder: _order,
        dayId: 'Saturday',
        from: '09:00',
        to: '14:00',
      );
      expect(result.days.map((d) => d.day).toList(), ['Saturday', 'Friday']);
    });

    test('rejects an overlapping candidate and leaves days untouched', () {
      final original = [
        (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
      ];
      final result = WeeklySchedulePolicy.upsertSlot(
        days: original,
        canonicalOrder: _order,
        dayId: 'Saturday',
        from: '13:00',
        to: '15:00',
      );
      expect(result.validation.isValid, isFalse);
      expect(result.validation.reason, SlotValidationReason.overlapsExisting);
      expect(result.days, same(original));
    });

    test('accepts an adjacent boundary-touching slot', () {
      final result = WeeklySchedulePolicy.upsertSlot(
        days: [
          (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
        ],
        canonicalOrder: _order,
        dayId: 'Saturday',
        from: '14:00',
        to: '18:00',
      );
      expect(result.validation.isValid, isTrue);
      expect(result.days.single.slots, hasLength(2));
    });
  });

  group('WeeklySchedulePolicy.removeSlot', () {
    test('deletes only the targeted slot', () {
      final result = WeeklySchedulePolicy.removeSlot(
        days: [
          (
            day: 'Saturday',
            slots: [_slot('09:00', '14:00'), _slot('15:00', '18:00')],
          ),
        ],
        dayId: 'Saturday',
        slotIndex: 0,
      );
      expect(result.single.slots, hasLength(1));
      expect(result.single.slots.single.from, '15:00');
    });

    test('leaves other days untouched', () {
      final result = WeeklySchedulePolicy.removeSlot(
        days: [
          (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
          (day: 'Sunday', slots: [_slot('09:00', '14:00')]),
        ],
        dayId: 'Saturday',
        slotIndex: 0,
      );
      expect(result, hasLength(1));
      expect(result.single.day, 'Sunday');
    });

    test('removing the last slot in a day drops that day group entirely', () {
      final result = WeeklySchedulePolicy.removeSlot(
        days: [
          (day: 'Saturday', slots: [_slot('09:00', '14:00')]),
        ],
        dayId: 'Saturday',
        slotIndex: 0,
      );
      expect(result, isEmpty);
    });
  });
}
