import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('DateValidators', () {
    group('latestBirthDateForMinAge', () {
      test('returns the cutoff date exactly minYears before the reference', () {
        final cutoff = DateValidators.latestBirthDateForMinAge(
          reference: DateTime(2026, 8, 13),
        );
        expect(cutoff, equals(DateTime(2010, 8, 13)));
      });
    });

    group('isOldEnough', () {
      // isOldEnough has no `reference` override (always compares against
      // DateTime.now() internally), so boundary cases are computed relative
      // to "now" rather than hardcoded absolute dates.
      DateTime cutoffFor(int minYears) =>
          DateValidators.latestBirthDateForMinAge(minYears: minYears);

      test(
        'accepts a birth date exactly minYears before the reference date',
        () {
          expect(DateValidators.isOldEnough(cutoffFor(16)), isTrue);
        },
      );

      test('accepts a birth date one day before the cutoff', () {
        expect(
          DateValidators.isOldEnough(
            cutoffFor(16).subtract(const Duration(days: 1)),
          ),
          isTrue,
        );
      });

      test('rejects a birth date one day after the cutoff', () {
        expect(
          DateValidators.isOldEnough(
            cutoffFor(16).add(const Duration(days: 1)),
          ),
          isFalse,
        );
      });

      test('rejects null birth date', () {
        expect(DateValidators.isOldEnough(null), isFalse);
      });

      test('defaults to age 16 when minYears is not provided', () {
        final barelyOldEnough = DateTime.now().subtract(
          const Duration(days: 16 * 365 + 10),
        );
        expect(DateValidators.isOldEnough(barelyOldEnough), isTrue);
      });
    });

    group('isNotExpired', () {
      test('accepts an expiry date after the reference date', () {
        expect(
          DateValidators.isNotExpired(
            DateTime(2026, 8, 14),
            reference: DateTime(2026, 8, 13),
          ),
          isTrue,
        );
      });

      test('accepts an expiry date equal to the reference date', () {
        expect(
          DateValidators.isNotExpired(
            DateTime(2026, 8, 13),
            reference: DateTime(2026, 8, 13),
          ),
          isTrue,
        );
      });

      test('rejects an expiry date before the reference date', () {
        expect(
          DateValidators.isNotExpired(
            DateTime(2026, 8, 12),
            reference: DateTime(2026, 8, 13),
          ),
          isFalse,
        );
      });

      test('rejects null expiry date', () {
        expect(DateValidators.isNotExpired(null), isFalse);
      });
    });
  });
}
