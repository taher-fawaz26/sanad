import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/policies/working_hours_policy.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/cubit/edit_working_hours_cubit.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/working_hours_section.dart';

void main() {
  group('EditWorkingHoursCubit', () {
    test('seeds state from initialEntries', () {
      final cubit = EditWorkingHoursCubit(
        initialEntries: const [
          WorkingHoursEditEntry(dayId: 'SATURDAY', from: '09:00', to: '18:00'),
        ],
      );
      expect(cubit.state.entries, hasLength(1));
      cubit.close();
    });

    test('defaults to an empty draft', () {
      final cubit = EditWorkingHoursCubit();
      expect(cubit.state.entries, isEmpty);
      cubit.close();
    });

    blocTest<EditWorkingHoursCubit, EditWorkingHoursDraft>(
      'add appends a new entry',
      build: EditWorkingHoursCubit.new,
      act: (cubit) => cubit.add(
        const WorkingHoursEditEntry(
          dayId: 'SATURDAY',
          from: '09:00',
          to: '18:00',
        ),
      ),
      expect: () => [
        isA<EditWorkingHoursDraft>().having(
          (s) => s.entries,
          'entries',
          hasLength(1),
        ),
      ],
    );

    blocTest<EditWorkingHoursCubit, EditWorkingHoursDraft>(
      'add allows a second slot for the same day (split shifts, SAN-568)',
      build: () => EditWorkingHoursCubit(
        initialEntries: const [
          WorkingHoursEditEntry(dayId: 'SATURDAY', from: '09:00', to: '12:00'),
        ],
      ),
      act: (cubit) => cubit.add(
        const WorkingHoursEditEntry(
          dayId: 'SATURDAY',
          from: '14:00',
          to: '18:00',
        ),
      ),
      expect: () => [
        isA<EditWorkingHoursDraft>().having(
          (s) => s.entries,
          'entries',
          hasLength(2),
        ),
      ],
    );

    test(
      'add rejects an overlapping slot at add-time (SAN-573) — draft is '
      'preserved and rejection is stashed for the sheet to render inline',
      () {
        final cubit = EditWorkingHoursCubit(
          initialEntries: const [
            WorkingHoursEditEntry(
              dayId: 'Saturday',
              from: '09:00',
              to: '14:00',
            ),
          ],
        );
        final result = cubit.add(
          const WorkingHoursEditEntry(
            dayId: 'Saturday',
            from: '13:00',
            to: '15:00',
          ),
        );
        expect(result.reason, SlotValidationReason.overlapsExisting);
        // Draft untouched — no silent mutation.
        expect(cubit.state.entries, hasLength(1));
        expect(cubit.state.entries.single.from, '09:00');
        // Rejection surfaced with the conflicting slot for the UI.
        expect(cubit.state.lastRejection, isNotNull);
        expect(cubit.state.lastRejection!.dayId, 'Saturday');
        expect(cubit.state.lastRejection!.conflict!.from, '09:00');
        cubit.close();
      },
    );

    test(
      'add allows an adjacent (touching-boundary) slot on the same day',
      () {
        final cubit = EditWorkingHoursCubit(
          initialEntries: const [
            WorkingHoursEditEntry(
              dayId: 'Saturday',
              from: '09:00',
              to: '14:00',
            ),
          ],
        );
        final result = cubit.add(
          const WorkingHoursEditEntry(
            dayId: 'Saturday',
            from: '14:00',
            to: '22:00',
          ),
        );
        expect(result.isValid, isTrue);
        expect(cubit.state.entries, hasLength(2));
        expect(cubit.state.lastRejection, isNull);
        cubit.close();
      },
    );

    test(
      'add accepts overlapping times on DIFFERENT days (per-day overlap only)',
      () {
        final cubit = EditWorkingHoursCubit(
          initialEntries: const [
            WorkingHoursEditEntry(
              dayId: 'Saturday',
              from: '09:00',
              to: '14:00',
            ),
          ],
        );
        final result = cubit.add(
          const WorkingHoursEditEntry(
            dayId: 'Sunday',
            from: '09:00',
            to: '14:00',
          ),
        );
        expect(result.isValid, isTrue);
        expect(cubit.state.entries, hasLength(2));
        cubit.close();
      },
    );

    test('a successful add after a rejection clears the pending rejection', () {
      final cubit = EditWorkingHoursCubit(
        initialEntries: const [
          WorkingHoursEditEntry(
            dayId: 'Saturday',
            from: '09:00',
            to: '14:00',
          ),
        ],
      );
      cubit.add(
        const WorkingHoursEditEntry(
          dayId: 'Saturday',
          from: '13:00',
          to: '15:00',
        ),
      );
      expect(cubit.state.lastRejection, isNotNull);
      cubit.add(
        const WorkingHoursEditEntry(
          dayId: 'Sunday',
          from: '10:00',
          to: '12:00',
        ),
      );
      expect(cubit.state.lastRejection, isNull);
      cubit.close();
    });

    blocTest<EditWorkingHoursCubit, EditWorkingHoursDraft>(
      'removeAt deletes only the row at that index, not by day id',
      build: () => EditWorkingHoursCubit(
        initialEntries: const [
          WorkingHoursEditEntry(dayId: 'SATURDAY', from: '09:00', to: '12:00'),
          WorkingHoursEditEntry(dayId: 'SATURDAY', from: '14:00', to: '18:00'),
        ],
      ),
      act: (cubit) => cubit.removeAt(0),
      expect: () => [
        isA<EditWorkingHoursDraft>()
            .having((s) => s.entries, 'entries', hasLength(1))
            .having((s) => s.entries.single.from, 'from', '14:00'),
      ],
    );
  });
}
