import 'package:core/core.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';
import 'package:test/test.dart';

void main() {
  group('PhoneValidator', () {
    group('isValid', () {
      test('accepts a valid mobile number for a strict country (AE)', () {
        expect(
          PhoneValidator.isValid('501234567', country: IsoCode.AE),
          isTrue,
        );
      });

      test('rejects an invalid number for a strict country (AE)', () {
        expect(
          PhoneValidator.isValid('12345', country: IsoCode.AE),
          isFalse,
        );
      });

      test('falls back to a loose digit-count check for non-strict '
          'countries', () {
        expect(
          PhoneValidator.isValid('+12025550123', country: IsoCode.US),
          isTrue,
        );
      });

      test('rejects a number too short for the loose fallback check', () {
        expect(
          PhoneValidator.isValid('123', country: IsoCode.US),
          isFalse,
        );
      });

      test('rejects null and empty', () {
        expect(PhoneValidator.isValid(null), isFalse);
        expect(PhoneValidator.isValid(''), isFalse);
        expect(PhoneValidator.isValid('   '), isFalse);
      });

      test('rejects unparseable input', () {
        expect(PhoneValidator.isValid('not a phone number'), isFalse);
      });
    });

    group('isoCodeFromName', () {
      test('resolves a known alpha-2 country code', () {
        expect(PhoneValidator.isoCodeFromName('AE'), equals(IsoCode.AE));
        expect(PhoneValidator.isoCodeFromName('ae'), equals(IsoCode.AE));
      });

      test('returns null for an unknown or empty code', () {
        expect(PhoneValidator.isoCodeFromName('ZZ'), isNull);
        expect(PhoneValidator.isoCodeFromName(''), isNull);
        expect(PhoneValidator.isoCodeFromName(null), isNull);
      });
    });
  });
}
