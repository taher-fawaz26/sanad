import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('UaePhoneValidator', () {
    group('isValid', () {
      test('accepts local mobile numbers (05XXXXXXXX)', () {
        expect(UaePhoneValidator.isValid('0501234567'), isTrue);
        expect(UaePhoneValidator.isValid('0551234567'), isTrue);
      });

      test('accepts international mobile numbers (9715XXXXXXXX)', () {
        expect(UaePhoneValidator.isValid('971501234567'), isTrue);
        expect(UaePhoneValidator.isValid('971551234567'), isTrue);
      });

      test('accepts local landline numbers (0[2-9]XXXXXXX)', () {
        expect(UaePhoneValidator.isValid('021234567'), isTrue);
        expect(UaePhoneValidator.isValid('041234567'), isTrue);
      });

      test('accepts international landline numbers (971[2-9]XXXXXXX)', () {
        expect(UaePhoneValidator.isValid('97121234567'), isTrue);
        expect(UaePhoneValidator.isValid('97141234567'), isTrue);
      });

      test('strips whitespace, dashes, and plus signs before validating', () {
        expect(UaePhoneValidator.isValid('+971501234567'), isTrue);
        expect(UaePhoneValidator.isValid('050 123 4567'), isTrue);
        expect(UaePhoneValidator.isValid('050-123-4567'), isTrue);
      });

      test('rejects null and empty', () {
        expect(UaePhoneValidator.isValid(null), isFalse);
        expect(UaePhoneValidator.isValid(''), isFalse);
        expect(UaePhoneValidator.isValid('   '), isFalse);
      });

      test('rejects numbers with wrong length', () {
        expect(UaePhoneValidator.isValid('050123'), isFalse);
        expect(UaePhoneValidator.isValid('05012345678'), isFalse);
      });

      test('rejects non-UAE numbers', () {
        expect(UaePhoneValidator.isValid('1234567890'), isFalse);
        expect(UaePhoneValidator.isValid('00201234567'), isFalse);
      });
    });

    group('validationMessage', () {
      test('returns null for valid numbers', () {
        expect(UaePhoneValidator.validationMessage('0501234567'), isNull);
      });

      test('returns null for empty input', () {
        expect(UaePhoneValidator.validationMessage(null), isNull);
        expect(UaePhoneValidator.validationMessage(''), isNull);
      });

      test('returns error key for invalid numbers', () {
        expect(
          UaePhoneValidator.validationMessage('12345'),
          equals('validation.form.uae_phone_invalid'),
        );
      });
    });

    group('normalize', () {
      test('prepends + to international format (971...)', () {
        expect(
          UaePhoneValidator.normalize('971501234567'),
          equals('+971501234567'),
        );
      });

      test('converts local format (0...) to international', () {
        expect(
          UaePhoneValidator.normalize('0501234567'),
          equals('+971501234567'),
        );
      });

      test('handles input already having +', () {
        expect(
          UaePhoneValidator.normalize('+971501234567'),
          equals('+971501234567'),
        );
      });

      test('strips whitespace and dashes before normalizing', () {
        expect(
          UaePhoneValidator.normalize('050 123 4567'),
          equals('+971501234567'),
        );
        expect(
          UaePhoneValidator.normalize('050-123-4567'),
          equals('+971501234567'),
        );
      });
    });
  });
}
