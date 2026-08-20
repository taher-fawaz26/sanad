import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('UaePhoneValidator', () {
    group('isMobile', () {
      test('accepts local mobile numbers (05XXXXXXXX)', () {
        expect(UaePhoneValidator.isMobile('0501234567'), isTrue);
        expect(UaePhoneValidator.isMobile('0551234567'), isTrue);
      });

      test('accepts national mobile numbers (5XXXXXXXX)', () {
        expect(UaePhoneValidator.isMobile('501234567'), isTrue);
        expect(UaePhoneValidator.isMobile('551234567'), isTrue);
      });

      test('accepts international mobile numbers (9715XXXXXXXX)', () {
        expect(UaePhoneValidator.isMobile('971501234567'), isTrue);
        expect(UaePhoneValidator.isMobile('971551234567'), isTrue);
      });

      test('strips whitespace, dashes, and plus signs before validating', () {
        expect(UaePhoneValidator.isMobile('+971501234567'), isTrue);
        expect(UaePhoneValidator.isMobile('050 123 4567'), isTrue);
        expect(UaePhoneValidator.isMobile('050-123-4567'), isTrue);
      });

      test('rejects landline numbers', () {
        expect(UaePhoneValidator.isMobile('021234567'), isFalse);
        expect(UaePhoneValidator.isMobile('41234567'), isFalse);
        expect(UaePhoneValidator.isMobile('97141234567'), isFalse);
      });

      test('rejects null and empty', () {
        expect(UaePhoneValidator.isMobile(null), isFalse);
        expect(UaePhoneValidator.isMobile(''), isFalse);
        expect(UaePhoneValidator.isMobile('   '), isFalse);
      });

      test('rejects numbers with wrong length', () {
        expect(UaePhoneValidator.isMobile('050123'), isFalse);
        expect(UaePhoneValidator.isMobile('05012345678'), isFalse);
      });
    });

    group('mobileValidationMessage', () {
      test('returns null for valid mobile numbers', () {
        expect(UaePhoneValidator.mobileValidationMessage('0501234567'), isNull);
      });

      test('returns null for empty input', () {
        expect(UaePhoneValidator.mobileValidationMessage(null), isNull);
        expect(UaePhoneValidator.mobileValidationMessage(''), isNull);
      });

      test('returns error key for landline numbers', () {
        expect(
          UaePhoneValidator.mobileValidationMessage('41234567'),
          equals('validation.form.uae_phone_invalid'),
        );
      });

      test('returns error key for invalid numbers', () {
        expect(
          UaePhoneValidator.mobileValidationMessage('12345'),
          equals('validation.form.uae_phone_invalid'),
        );
      });
    });

    group('isValid', () {
      test('accepts local mobile numbers (05XXXXXXXX)', () {
        expect(UaePhoneValidator.isValid('0501234567'), isTrue);
        expect(UaePhoneValidator.isValid('0551234567'), isTrue);
      });

      test('accepts national mobile numbers (5XXXXXXXX)', () {
        expect(UaePhoneValidator.isValid('501234567'), isTrue);
        expect(UaePhoneValidator.isValid('551234567'), isTrue);
      });

      test('accepts international mobile numbers (9715XXXXXXXX)', () {
        expect(UaePhoneValidator.isValid('971501234567'), isTrue);
        expect(UaePhoneValidator.isValid('971551234567'), isTrue);
      });

      test('accepts local landline numbers (0[2-9]XXXXXXX)', () {
        expect(UaePhoneValidator.isValid('021234567'), isTrue);
        expect(UaePhoneValidator.isValid('041234567'), isTrue);
      });

      test('accepts national landline numbers ([2-9]XXXXXXX)', () {
        expect(UaePhoneValidator.isValid('21234567'), isTrue);
        expect(UaePhoneValidator.isValid('41234567'), isTrue);
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

    group('toNationalInput', () {
      test('strips +971 / 971 / trunk 0 for AppPhoneField', () {
        expect(
          UaePhoneValidator.toNationalInput('+971500000006'),
          equals('500000006'),
        );
        expect(
          UaePhoneValidator.toNationalInput('971501234567'),
          equals('501234567'),
        );
        expect(
          UaePhoneValidator.toNationalInput('0501234567'),
          equals('501234567'),
        );
        expect(
          UaePhoneValidator.toNationalInput('501234567'),
          equals('501234567'),
        );
      });

      test('returns empty for null or blank', () {
        expect(UaePhoneValidator.toNationalInput(null), isEmpty);
        expect(UaePhoneValidator.toNationalInput('   '), isEmpty);
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

      test('converts national format (5...) to international', () {
        expect(
          UaePhoneValidator.normalize('501234567'),
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
