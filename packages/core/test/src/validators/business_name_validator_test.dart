import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('BusinessNameValidator', () {
    group('isValid', () {
      test('rejects null, empty, and whitespace-only values', () {
        expect(BusinessNameValidator.isValid(null), isFalse);
        expect(BusinessNameValidator.isValid(''), isFalse);
        expect(BusinessNameValidator.isValid('   '), isFalse);
      });

      test('rejects symbol-only values', () {
        expect(BusinessNameValidator.isValid('@@@@@'), isFalse);
        expect(BusinessNameValidator.isValid('######'), isFalse);
        expect(BusinessNameValidator.isValid('!!!!!!'), isFalse);
        expect(BusinessNameValidator.isValid('______'), isFalse);
        expect(BusinessNameValidator.isValid('%%%%%%'), isFalse);
      });

      test('rejects digits-only values', () {
        expect(BusinessNameValidator.isValid('12345'), isFalse);
      });

      test('rejects disallowed symbols even alongside letters', () {
        expect(BusinessNameValidator.isValid('Branch @1'), isFalse);
        expect(BusinessNameValidator.isValid('Service #1'), isFalse);
        expect(BusinessNameValidator.isValid('50% Off <Deals>'), isFalse);
        expect(BusinessNameValidator.isValid('Team {Alpha}'), isFalse);
        expect(BusinessNameValidator.isValid('A=B Services'), isFalse);
      });

      test('accepts plain English and Arabic business names', () {
        expect(BusinessNameValidator.isValid('Main Branch'), isTrue);
        expect(BusinessNameValidator.isValid('الفرع الرئيسي'), isTrue);
      });

      test('accepts names with digits', () {
        expect(BusinessNameValidator.isValid('Branch 12'), isTrue);
      });

      test('accepts an ampersand between words', () {
        expect(BusinessNameValidator.isValid('A & B Services'), isTrue);
      });

      test('accepts a hyphen and an apostrophe', () {
        expect(BusinessNameValidator.isValid('24-Hour Plumbing'), isTrue);
        expect(BusinessNameValidator.isValid("O'Connor Services"), isTrue);
      });

      test('accepts a period and a comma', () {
        expect(BusinessNameValidator.isValid('Plumbing Co.'), isTrue);
        expect(BusinessNameValidator.isValid('Smith, Sons & Co'), isTrue);
      });
    });
  });
}
