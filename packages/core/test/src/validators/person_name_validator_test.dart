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
  });
}
