import 'package:branches/src/data/models/branch_availability_dto.dart';
import 'package:branches/src/data/models/branch_dto.dart';
import 'package:branches/src/domain/entities/branch_availability_mode.dart';
import 'package:branches/src/domain/entities/branch_weekdays.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BranchDto custom availability parsing (SAN-780)', () {
    // The EXACT real-device branch payload from the ticket: a CUSTOM branch
    // whose availability the backend returns with Title-case day codes.
    final realJson = <String, dynamic>{
      'id': '5603e64b-df27-422f-b847-12dba92bb99f',
      'branchName': 'Al Dhaid',
      'availabilityMode': 'CUSTOM',
      'availability': [
        {
          'day': 'Saturday',
          'slots': [
            {'to': '18:00', 'from': '14:00'},
            {'to': '21:00', 'from': '18:05'},
          ],
        },
        {
          'day': 'Tuesday',
          'slots': [
            {'to': '14:00', 'from': '10:00'},
          ],
        },
        {
          'day': 'Friday',
          'slots': [
            {'to': '14:00', 'from': '10:00'},
          ],
        },
      ],
    };

    test(
      'normalizes the Title-case backend day codes to canonical all-caps so '
      'the details summary lookup against BranchWeekdays.all hits',
      () {
        final branch = BranchDto.fromJson(realJson).toDomain();

        expect(branch.availabilityMode, BranchAvailabilityMode.custom);

        final availability = branch.availability!;
        expect(availability.map((day) => day.day), [
          BranchWeekdays.saturday,
          BranchWeekdays.tuesday,
          BranchWeekdays.friday,
        ]);
        // Every produced day code is one BranchWeekdays.all recognizes.
        for (final day in availability) {
          expect(BranchWeekdays.all, contains(day.day));
        }
      },
    );

    test('preserves both Saturday slots and their times', () {
      final branch = BranchDto.fromJson(realJson).toDomain();

      final saturday = branch.availability!.firstWhere(
        (day) => day.day == BranchWeekdays.saturday,
      );
      expect(saturday.slots, hasLength(2));
      expect(saturday.slots[0].from, '14:00');
      expect(saturday.slots[0].to, '18:00');
      expect(saturday.slots[1].from, '18:05');
      expect(saturday.slots[1].to, '21:00');
    });

    // The write-path regression: after read normalizes to canonical all-caps,
    // serializing the SAME branch back MUST emit Title-case day codes — sending
    // "SATURDAY" is rejected with 400 (SAN-780 write regression).
    test(
      'round-trips read→write: canonical all-caps domain serializes back to '
      'the backend Title-case day spelling',
      () {
        final branch = BranchDto.fromJson(realJson).toDomain();

        final serialized = branch.availability!
            .map(BranchAvailabilityDto.entityToMap)
            .toList();

        // Title-case, never the canonical all-caps that triggered the 400.
        expect(serialized.map((m) => m['day']), [
          'Saturday',
          'Tuesday',
          'Friday',
        ]);
        // Slots are carried through unchanged.
        final saturday = serialized.first;
        expect(saturday['slots'], [
          {'from': '14:00', 'to': '18:00'},
          {'from': '18:05', 'to': '21:00'},
        ]);
      },
    );
  });
}
