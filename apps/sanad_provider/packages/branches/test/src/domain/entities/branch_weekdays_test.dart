import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BranchWeekdays.normalize', () {
    test(
      'maps the Title-case company-schedule day codes onto the all-caps '
      'branch codes in BranchWeekdays.all (SAN-780)',
      () {
        // The exact spellings `service-provider/working-hours` returns.
        const titleCase = {
          'Saturday': BranchWeekdays.saturday,
          'Sunday': BranchWeekdays.sunday,
          'Monday': BranchWeekdays.monday,
          'Tuesday': BranchWeekdays.tuesday,
          'Wednesday': BranchWeekdays.wednesday,
          'Thursday': BranchWeekdays.thursday,
          'Friday': BranchWeekdays.friday,
        };

        for (final entry in titleCase.entries) {
          final normalized = BranchWeekdays.normalize(entry.key);
          expect(normalized, entry.value);
          expect(BranchWeekdays.all, contains(normalized));
        }
      },
    );

    test('leaves already-canonical all-caps codes unchanged', () {
      for (final day in BranchWeekdays.all) {
        expect(BranchWeekdays.normalize(day), day);
      }
    });
  });

  group('BranchWeekdays.toApiDay (SAN-780 write path)', () {
    test(
      'maps each canonical all-caps day to the backend Title-case spelling',
      () {
        const expected = {
          BranchWeekdays.saturday: 'Saturday',
          BranchWeekdays.sunday: 'Sunday',
          BranchWeekdays.monday: 'Monday',
          BranchWeekdays.tuesday: 'Tuesday',
          BranchWeekdays.wednesday: 'Wednesday',
          BranchWeekdays.thursday: 'Thursday',
          BranchWeekdays.friday: 'Friday',
        };
        for (final entry in expected.entries) {
          expect(BranchWeekdays.toApiDay(entry.key), entry.value);
        }
      },
    );

    test(
      'round-trips read→write for all seven days (Title→canonical→Title)',
      () {
        const backendDays = [
          'Saturday',
          'Sunday',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        ];
        for (final day in backendDays) {
          expect(BranchWeekdays.toApiDay(BranchWeekdays.normalize(day)), day);
        }
      },
    );

    test(
      'is case-insensitive on input (already Title-case stays Title-case)',
      () {
        expect(BranchWeekdays.toApiDay('Saturday'), 'Saturday');
        expect(BranchWeekdays.toApiDay('saturday'), 'Saturday');
      },
    );
  });
}
