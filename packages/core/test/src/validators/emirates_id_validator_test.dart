import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('EmiratesIdValidator', () {
    group('normalizeDigits', () {
      test('strips hyphens and spaces from a formatted id', () {
        expect(
          EmiratesIdValidator.normalizeDigits('784-1234-1234567-1'),
          equals('784123412345671'),
        );
        expect(
          EmiratesIdValidator.normalizeDigits('784 1234 1234567 1'),
          equals('784123412345671'),
        );
      });

      test('returns empty string for null', () {
        expect(EmiratesIdValidator.normalizeDigits(null), isEmpty);
      });
    });

    group('isValid', () {
      test('accepts a valid 15-digit id with the 784 issuer prefix', () {
        expect(EmiratesIdValidator.isValid('784123412345671'), isTrue);
        expect(EmiratesIdValidator.isValid('784-1234-1234567-1'), isTrue);
      });

      test('rejects an id with the wrong length', () {
        expect(EmiratesIdValidator.isValid('78412341234567'), isFalse);
        expect(EmiratesIdValidator.isValid('7841234123456711'), isFalse);
      });

      test('rejects an id with the wrong issuer prefix', () {
        expect(EmiratesIdValidator.isValid('785123412345671'), isFalse);
      });

      test('rejects non-digit characters mixed into the digits', () {
        expect(EmiratesIdValidator.isValid('78412341234567A'), isFalse);
      });

      test('rejects null and empty', () {
        expect(EmiratesIdValidator.isValid(null), isFalse);
        expect(EmiratesIdValidator.isValid(''), isFalse);
      });
    });

    group('formatApiHyphenated', () {
      test('formats a valid 15-digit id into grouped hyphenated form', () {
        expect(
          EmiratesIdValidator.formatApiHyphenated('784123412345671'),
          equals('784-1234-1234567-1'),
        );
      });

      test('returns the trimmed raw input unchanged when invalid', () {
        expect(
          EmiratesIdValidator.formatApiHyphenated('  12345  '),
          equals('12345'),
        );
      });

      test('returns null for null input', () {
        expect(EmiratesIdValidator.formatApiHyphenated(null), isNull);
      });

      test('returns null for empty/whitespace-only input', () {
        expect(EmiratesIdValidator.formatApiHyphenated(''), isNull);
        expect(EmiratesIdValidator.formatApiHyphenated('   '), isNull);
      });
    });
  });
}
