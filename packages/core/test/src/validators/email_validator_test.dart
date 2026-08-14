import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('EmailValidator', () {
    group('isValid', () {
      test('accepts valid email formats', () {
        expect(EmailValidator.isValid('user@example.com'), isTrue);
        expect(EmailValidator.isValid('first.last+tag@sub.domain.co'), isTrue);
        expect(EmailValidator.isValid('user_name-1@my-domain.io'), isTrue);
      });

      test('rejects missing @ symbol', () {
        expect(EmailValidator.isValid('userexample.com'), isFalse);
      });

      test('rejects missing domain', () {
        expect(EmailValidator.isValid('user@'), isFalse);
      });

      test('rejects missing local part', () {
        expect(EmailValidator.isValid('@example.com'), isFalse);
      });

      test('rejects TLD shorter than 2 characters', () {
        expect(EmailValidator.isValid('user@example.c'), isFalse);
      });

      test('accepts TLD exactly 2 characters', () {
        expect(EmailValidator.isValid('user@example.co'), isTrue);
      });

      test('rejects null', () {
        expect(EmailValidator.isValid(null), isFalse);
      });

      test('rejects empty string', () {
        expect(EmailValidator.isValid(''), isFalse);
      });

      test('rejects whitespace-only string', () {
        expect(EmailValidator.isValid('   '), isFalse);
      });

      test('trims leading/trailing whitespace before validating', () {
        expect(EmailValidator.isValid('  user@example.com  '), isTrue);
      });
    });
  });
}
