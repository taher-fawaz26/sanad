import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';

WorkingHoursSlotEntity _slot(String from, String to) =>
    WorkingHoursSlotEntity(from: from, to: to);

void main() {
  group('WorkingHoursPolicy.validateSlotTimes', () {
    test('valid slot passes', () {
      expect(
        WorkingHoursPolicy.validateSlotTimes(
          from: '09:00',
          to: '14:00',
        ).isValid,
        isTrue,
      );
    });

    test('start == end is rejected (zero-duration)', () {
      final result = WorkingHoursPolicy.validateSlotTimes(
        from: '09:00',
        to: '09:00',
      );
      expect(result.reason, SlotValidationReason.endBeforeOrEqualStart);
    });

    test('start > end is rejected (no overnight support)', () {
      final result = WorkingHoursPolicy.validateSlotTimes(
        from: '18:00',
        to: '02:00',
      );
      expect(result.reason, SlotValidationReason.endBeforeOrEqualStart);
    });

    test('malformed time rejected', () {
      expect(
        WorkingHoursPolicy.validateSlotTimes(from: 'nope', to: '14:00').reason,
        SlotValidationReason.malformed,
      );
      expect(
        WorkingHoursPolicy.validateSlotTimes(from: '25:00', to: '26:00').reason,
        SlotValidationReason.malformed,
      );
    });
  });

  group('WorkingHoursPolicy.validateCandidateAgainst', () {
    final existing = [_slot('09:00', '14:00')];

    test('exact duplicate rejected', () {
      final result = WorkingHoursPolicy.validateCandidateAgainst(
        from: '09:00',
        to: '14:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
      expect(result.conflict, existing.first);
    });

    test('partial overlap rejected', () {
      final result = WorkingHoursPolicy.validateCandidateAgainst(
        from: '13:00',
        to: '15:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
    });

    test('contained slot rejected', () {
      final result = WorkingHoursPolicy.validateCandidateAgainst(
        from: '10:00',
        to: '12:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
    });

    test('containing slot rejected', () {
      final result = WorkingHoursPolicy.validateCandidateAgainst(
        from: '08:00',
        to: '15:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.overlapsExisting);
    });

    test('boundary-touching slot (adjacent) is VALID', () {
      expect(
        WorkingHoursPolicy.validateCandidateAgainst(
          from: '14:00',
          to: '22:00',
          existingSlots: existing,
        ).isValid,
        isTrue,
      );
      expect(
        WorkingHoursPolicy.validateCandidateAgainst(
          from: '08:00',
          to: '09:00',
          existingSlots: existing,
        ).isValid,
        isTrue,
      );
    });

    test('non-overlapping slot before existing is valid', () {
      expect(
        WorkingHoursPolicy.validateCandidateAgainst(
          from: '06:00',
          to: '08:00',
          existingSlots: existing,
        ).isValid,
        isTrue,
      );
    });

    test('excludeIndex allows editing a slot with its own current range', () {
      final result = WorkingHoursPolicy.validateCandidateAgainst(
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
        final result = WorkingHoursPolicy.validateCandidateAgainst(
          from: '15:00',
          to: '17:00',
          existingSlots: [_slot('09:00', '14:00'), _slot('16:00', '18:00')],
          excludeIndex: 0,
        );
        expect(result.reason, SlotValidationReason.overlapsExisting);
      },
    );

    test('candidate with start >= end is rejected before overlap check', () {
      final result = WorkingHoursPolicy.validateCandidateAgainst(
        from: '14:00',
        to: '09:00',
        existingSlots: existing,
      );
      expect(result.reason, SlotValidationReason.endBeforeOrEqualStart);
    });
  });

  group('WorkingHoursPolicy.sortSlotsChronologically', () {
    test('sorts by from time', () {
      final result = WorkingHoursPolicy.sortSlotsChronologically([
        _slot('16:00', '22:00'),
        _slot('09:00', '15:00'),
      ]);
      expect(result.first.from, '09:00');
      expect(result.last.from, '16:00');
    });

    test('input is not mutated', () {
      final input = [_slot('16:00', '22:00'), _slot('09:00', '15:00')];
      WorkingHoursPolicy.sortSlotsChronologically(input);
      expect(input.first.from, '16:00');
    });
  });

  group('WorkingHoursPolicy.sortDaysCanonically', () {
    test('always Saturday → Friday regardless of input order', () {
      final result = WorkingHoursPolicy.sortDaysCanonically([
        WorkingHoursDayEntity(day: WorkingHoursDayIds.friday, slots: const []),
        WorkingHoursDayEntity(day: WorkingHoursDayIds.monday, slots: const []),
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: const [],
        ),
      ]);
      expect(
        result.map((d) => d.day).toList(),
        [
          WorkingHoursDayIds.saturday,
          WorkingHoursDayIds.monday,
          WorkingHoursDayIds.friday,
        ],
      );
    });

    test('unknown day codes pushed to end (defensive)', () {
      final result = WorkingHoursPolicy.sortDaysCanonically([
        WorkingHoursDayEntity(day: 'BOGUS', slots: const []),
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: const [],
        ),
      ]);
      expect(result.first.day, WorkingHoursDayIds.saturday);
      expect(result.last.day, 'BOGUS');
    });
  });

  group('WorkingHoursPolicy.normalizeAvailability', () {
    test(
      'merges two separate entries for the SAME day into one group '
      '(SAN-573: a newly-added slot must never render as a second, '
      'separate day entry)',
      () {
        final result = WorkingHoursPolicy.normalizeAvailability([
          WorkingHoursDayEntity(
            day: WorkingHoursDayIds.saturday,
            slots: [_slot('09:00', '14:00')],
          ),
          WorkingHoursDayEntity(
            day: WorkingHoursDayIds.saturday,
            slots: [_slot('14:00', '18:00')],
          ),
        ]);
        expect(result, hasLength(1));
        expect(result.single.slots, hasLength(2));
      },
    );

    test('sorts days Saturday → Friday regardless of input order', () {
      final result = WorkingHoursPolicy.normalizeAvailability([
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.friday,
          slots: [_slot('10:00', '14:00')],
        ),
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [_slot('10:00', '14:00')],
        ),
      ]);
      expect(result.map((d) => d.day).toList(), [
        WorkingHoursDayIds.saturday,
        WorkingHoursDayIds.friday,
      ]);
    });

    test('sorts slots chronologically within each merged day', () {
      final result = WorkingHoursPolicy.normalizeAvailability([
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [_slot('16:00', '22:00')],
        ),
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [_slot('09:00', '14:00')],
        ),
      ]);
      expect(result.single.slots[0].from, '09:00');
      expect(result.single.slots[1].from, '16:00');
    });

    test('empty availability yields an empty list', () {
      expect(WorkingHoursPolicy.normalizeAvailability(const []), isEmpty);
    });

    test('does not mutate the input list', () {
      final input = [
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.friday,
          slots: [_slot('10:00', '14:00')],
        ),
      ];
      WorkingHoursPolicy.normalizeAvailability(input);
      expect(input.single.day, WorkingHoursDayIds.friday);
    });
  });

  group('WorkingHoursPolicy.findAvailabilityConflict', () {
    test('clean availability returns null', () {
      final result = WorkingHoursPolicy.findAvailabilityConflict([
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [_slot('09:00', '14:00'), _slot('15:00', '18:00')],
        ),
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.sunday,
          slots: [_slot('10:00', '16:00')],
        ),
      ]);
      expect(result, isNull);
    });

    test('adjacent slots on same day treated as valid (no conflict)', () {
      final result = WorkingHoursPolicy.findAvailabilityConflict([
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [_slot('09:00', '14:00'), _slot('14:00', '22:00')],
        ),
      ]);
      expect(result, isNull);
    });

    test('same-day overlap surfaced with both slots', () {
      final a = _slot('09:00', '14:00');
      final b = _slot('13:00', '15:00');
      final result = WorkingHoursPolicy.findAvailabilityConflict([
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [a, b],
        ),
      ]);
      expect(result, isNotNull);
      expect(result!.day, WorkingHoursDayIds.saturday);
      expect(result.first, a);
      expect(result.second, b);
    });

    test('different-day overlap allowed (not a conflict)', () {
      final result = WorkingHoursPolicy.findAvailabilityConflict([
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.saturday,
          slots: [_slot('09:00', '14:00')],
        ),
        WorkingHoursDayEntity(
          day: WorkingHoursDayIds.sunday,
          slots: [_slot('09:00', '14:00')],
        ),
      ]);
      expect(result, isNull);
    });
  });
}
