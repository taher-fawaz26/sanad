import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/working_hours_day_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/cubit/edit_working_hours_cubit.dart';

WorkingHoursDayEntity _day(String day, List<WorkingHoursSlotEntity> slots) =>
    WorkingHoursDayEntity(day: day, slots: slots);

WorkingHoursSlotEntity _slot(String from, String to) =>
    WorkingHoursSlotEntity(from: from, to: to);

void main() {
  group('EditWorkingHoursCubit', () {
    test('seeds state from initialDays, normalized', () {
      final cubit = EditWorkingHoursCubit(
        initialDays: [
          _day('Friday', [_slot('10:00', '14:00')]),
          _day('Saturday', [_slot('09:00', '18:00')]),
        ],
      );
      // Saturday must sort before Friday even though it was passed second.
      expect(cubit.state.days.map((d) => d.day).toList(), [
        'Saturday',
        'Friday',
      ]);
      cubit.close();
    });

    test('defaults to an empty draft', () {
      final cubit = EditWorkingHoursCubit();
      expect(cubit.state.days, isEmpty);
      cubit.close();
    });

    test('addSlot to a NEW day creates a new day group', () {
      final cubit = EditWorkingHoursCubit();
      final result = cubit.addSlot(
        dayId: 'Saturday',
        from: '09:00',
        to: '18:00',
      );
      expect(result.isValid, isTrue);
      expect(cubit.state.days, hasLength(1));
      expect(cubit.state.days.single.day, 'Saturday');
      expect(cubit.state.days.single.slots, hasLength(1));
      cubit.close();
    });

    test(
      'addSlot to an EXISTING day merges into that day\'s group — the '
      'SAN-573 bug (new slot appended as a separate trailing day) must not '
      'reproduce',
      () {
        final cubit = EditWorkingHoursCubit(
          initialDays: [
            _day('Saturday', [_slot('10:00', '14:00')]),
            _day('Tuesday', [_slot('10:00', '14:00')]),
            _day('Friday', [_slot('10:00', '14:00')]),
          ],
        );

        cubit.addSlot(dayId: 'Saturday', from: '14:00', to: '18:00');

        // Still exactly 3 day groups — no duplicate/new Saturday entry.
        expect(cubit.state.days, hasLength(3));
        final saturday = cubit.state.days.firstWhere(
          (d) => d.day == 'Saturday',
        );
        expect(saturday.slots, hasLength(2));
        expect(saturday.slots[0].from, '10:00');
        expect(saturday.slots[1].from, '14:00');

        // Canonical order preserved: Saturday, Tuesday, Friday.
        expect(cubit.state.days.map((d) => d.day).toList(), [
          'Saturday',
          'Tuesday',
          'Friday',
        ]);
        cubit.close();
      },
    );

    test(
      'a second addSlot to the same day merges again into the SAME group '
      '(matches the end-to-end example in the spec)',
      () {
        final cubit = EditWorkingHoursCubit(
          initialDays: [
            _day('Saturday', [_slot('10:00', '14:00')]),
          ],
        );

        cubit.addSlot(dayId: 'Saturday', from: '14:00', to: '18:00');
        cubit.addSlot(dayId: 'Saturday', from: '18:00', to: '21:00');

        expect(cubit.state.days, hasLength(1));
        expect(cubit.state.days.single.slots, hasLength(3));
        expect(cubit.state.days.single.slots[0].from, '10:00');
        expect(cubit.state.days.single.slots[1].from, '14:00');
        expect(cubit.state.days.single.slots[2].from, '18:00');
        cubit.close();
      },
    );

    test('new day is inserted in canonical position, not appended', () {
      final cubit = EditWorkingHoursCubit(
        initialDays: [
          _day('Saturday', [_slot('10:00', '14:00')]),
          _day('Friday', [_slot('10:00', '14:00')]),
        ],
      );

      cubit.addSlot(dayId: 'Sunday', from: '10:00', to: '14:00');

      expect(cubit.state.days.map((d) => d.day).toList(), [
        'Saturday',
        'Sunday',
        'Friday',
      ]);
      cubit.close();
    });

    test(
      'addSlot rejects an overlapping slot — draft is preserved and '
      'rejection is stashed for the sheet to render inline',
      () {
        final cubit = EditWorkingHoursCubit(
          initialDays: [
            _day('Saturday', [_slot('09:00', '14:00')]),
          ],
        );
        final result = cubit.addSlot(
          dayId: 'Saturday',
          from: '13:00',
          to: '15:00',
        );
        expect(result.reason, SlotValidationReason.overlapsExisting);
        // Draft untouched — no silent mutation.
        expect(cubit.state.days.single.slots, hasLength(1));
        expect(cubit.state.days.single.slots.single.from, '09:00');
        // Rejection surfaced with the conflicting slot for the UI.
        expect(cubit.state.lastRejection, isNotNull);
        expect(cubit.state.lastRejection!.dayId, 'Saturday');
        expect(cubit.state.lastRejection!.conflict!.from, '09:00');
        cubit.close();
      },
    );

    test(
      'addSlot allows an adjacent (touching-boundary) slot on the same day',
      () {
        final cubit = EditWorkingHoursCubit(
          initialDays: [
            _day('Saturday', [_slot('09:00', '14:00')]),
          ],
        );
        final result = cubit.addSlot(
          dayId: 'Saturday',
          from: '14:00',
          to: '22:00',
        );
        expect(result.isValid, isTrue);
        expect(cubit.state.days.single.slots, hasLength(2));
        expect(cubit.state.lastRejection, isNull);
        cubit.close();
      },
    );

    test(
      'a successful addSlot after a rejection clears the pending rejection',
      () {
        final cubit = EditWorkingHoursCubit(
          initialDays: [
            _day('Saturday', [_slot('09:00', '14:00')]),
          ],
        );
        cubit.addSlot(dayId: 'Saturday', from: '13:00', to: '15:00');
        expect(cubit.state.lastRejection, isNotNull);
        cubit.addSlot(dayId: 'Sunday', from: '10:00', to: '12:00');
        expect(cubit.state.lastRejection, isNull);
        cubit.close();
      },
    );

    blocTest<EditWorkingHoursCubit, EditWorkingHoursDraft>(
      'removeSlot deletes only that slot, not the whole day',
      build: () => EditWorkingHoursCubit(
        initialDays: [
          _day('Saturday', [_slot('09:00', '12:00'), _slot('14:00', '18:00')]),
        ],
      ),
      act: (cubit) => cubit.removeSlot('Saturday', 0),
      expect: () => [
        isA<EditWorkingHoursDraft>().having(
          (s) => s.days.single.slots,
          'Saturday.slots',
          [_slot('14:00', '18:00')],
        ),
      ],
    );

    test('removeSlot leaves other days untouched', () {
      final cubit = EditWorkingHoursCubit(
        initialDays: [
          _day('Saturday', [_slot('09:00', '12:00'), _slot('14:00', '18:00')]),
          _day('Tuesday', [_slot('10:00', '14:00')]),
        ],
      );
      cubit.removeSlot('Saturday', 0);
      expect(cubit.state.days, hasLength(2));
      final tuesday = cubit.state.days.firstWhere((d) => d.day == 'Tuesday');
      expect(tuesday.slots, hasLength(1));
      cubit.close();
    });

    test('removing the last slot in a day drops that day group entirely', () {
      final cubit = EditWorkingHoursCubit(
        initialDays: [
          _day('Saturday', [_slot('09:00', '12:00')]),
          _day('Tuesday', [_slot('10:00', '14:00')]),
        ],
      );
      cubit.removeSlot('Saturday', 0);
      expect(cubit.state.days, hasLength(1));
      expect(cubit.state.days.single.day, 'Tuesday');
      cubit.close();
    });
  });
}
