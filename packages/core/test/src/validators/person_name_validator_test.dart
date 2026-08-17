import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('PersonNameValidator', () {
    group('isValid', () {
      test('accepts a first and last name', () {
        expect(PersonNameValidator.isValid('John Smith'), isTrue);
      });

      test('accepts names with apostrophes and hyphens', () {
        expect(PersonNameValidator.isValid("O'Brien Jones"), isTrue);
        expect(PersonNameValidator.isValid('Anne-Marie Curie'), isTrue);
      });

      test('accepts unicode letters', () {
        expect(PersonNameValidator.isValid('محمد أحمد'), isTrue);
      });

      test('tolerates extra whitespace between words', () {
        expect(PersonNameValidator.isValid('John   Smith'), isTrue);
      });

      test('rejects a single word', () {
        expect(PersonNameValidator.isValid('John'), isFalse);
      });

      test('rejects names containing digits', () {
        expect(PersonNameValidator.isValid('John 3rd'), isFalse);
      });

      test('rejects names containing symbols other than apostrophe/hyphen', () {
        expect(PersonNameValidator.isValid('John @Smith'), isFalse);
      });

      test('rejects null', () {
        expect(PersonNameValidator.isValid(null), isFalse);
      });

      test('rejects empty and whitespace-only strings', () {
        expect(PersonNameValidator.isValid(''), isFalse);
        expect(PersonNameValidator.isValid('   '), isFalse);
      });
    });

    group('isValid with minWords: 1', () {
      test('accepts a single word name', () {
        expect(PersonNameValidator.isValid('Ahmed', minWords: 1), isTrue);
      });

      test('still rejects symbols-only input', () {
        expect(PersonNameValidator.isValid('@@@', minWords: 1), isFalse);
      });

      test('still rejects digits', () {
        expect(PersonNameValidator.isValid('123', minWords: 1), isFalse);
      });

      test('still accepts a multi-word name', () {
        expect(PersonNameValidator.isValid('John Smith', minWords: 1), isTrue);
      });
    });
  });
}
