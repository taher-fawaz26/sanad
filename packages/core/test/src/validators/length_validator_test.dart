import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('LengthValidator', () {
    group('isValid', () {
      test('accepts a value within min and max bounds', () {
        expect(
          LengthValidator.isValid('John', minLength: 3, maxLength: 255),
          isTrue,
        );
      });

      test('accepts a value exactly at the minimum boundary', () {
        expect(LengthValidator.isValid('abc', minLength: 3), isTrue);
      });

      test('rejects a value one character below the minimum', () {
        expect(LengthValidator.isValid('ab', minLength: 3), isFalse);
      });

      test('accepts a value exactly at the maximum boundary', () {
        expect(LengthValidator.isValid('abc', maxLength: 3), isTrue);
      });

      test('rejects a value one character above the maximum', () {
        expect(LengthValidator.isValid('abcd', maxLength: 3), isFalse);
      });

      test('trims before measuring length', () {
        expect(LengthValidator.isValid('  ab  ', minLength: 3), isFalse);
        expect(LengthValidator.isValid('  abc  ', minLength: 3), isTrue);
      });

      test('treats null as an empty string', () {
        expect(LengthValidator.isValid(null, minLength: 1), isFalse);
        expect(LengthValidator.isValid(null, maxLength: 10), isTrue);
      });

      test('is a no-op when neither bound is provided', () {
        expect(LengthValidator.isValid('anything'), isTrue);
        expect(LengthValidator.isValid(null), isTrue);
        expect(LengthValidator.isValid(''), isTrue);
      });
    });
  });
}
