import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('MeaningfulTextValidator', () {
    group('isValid', () {
      test('rejects null', () {
        expect(MeaningfulTextValidator.isValid(null), isFalse);
      });

      test('rejects empty and whitespace-only strings', () {
        expect(MeaningfulTextValidator.isValid(''), isFalse);
        expect(MeaningfulTextValidator.isValid('   '), isFalse);
      });

      test('rejects symbol-only values', () {
        expect(MeaningfulTextValidator.isValid('@@@@@@'), isFalse);
        expect(MeaningfulTextValidator.isValid('#######'), isFalse);
        expect(MeaningfulTextValidator.isValid(r'$$$$$$'), isFalse);
        expect(MeaningfulTextValidator.isValid('%%%%%%'), isFalse);
        expect(MeaningfulTextValidator.isValid('!!!!!!!'), isFalse);
        expect(MeaningfulTextValidator.isValid('______'), isFalse);
        expect(MeaningfulTextValidator.isValid('-----'), isFalse);
        expect(MeaningfulTextValidator.isValid('*****'), isFalse);
        expect(MeaningfulTextValidator.isValid('++++'), isFalse);
        expect(MeaningfulTextValidator.isValid('/////'), isFalse);
        expect(MeaningfulTextValidator.isValid('.....'), isFalse);
        expect(MeaningfulTextValidator.isValid(',,,,,'), isFalse);
      });

      test('rejects punctuation-only values', () {
        expect(MeaningfulTextValidator.isValid('..,,,'), isFalse);
      });

      test('rejects emoji-only values', () {
        expect(MeaningfulTextValidator.isValid('😀😀😀'), isFalse);
      });

      test('rejects digits-only values', () {
        expect(MeaningfulTextValidator.isValid('123456'), isFalse);
      });

      test('accepts English text', () {
        expect(
          MeaningfulTextValidator.isValid(
            'Emergency plumbing repair service for residential properties.',
          ),
          isTrue,
        );
      });

      test('accepts Arabic text', () {
        expect(
          MeaningfulTextValidator.isValid(
            'خدمة إصلاح تسربات المياه وتركيب الأدوات الصحية.',
          ),
          isTrue,
        );
      });

      test('accepts mixed Arabic/English text', () {
        expect(
          MeaningfulTextValidator.isValid(
            'Available 24/7 - متاح على مدار الساعة',
          ),
          isTrue,
        );
      });

      test('accepts text combined with numbers', () {
        expect(
          MeaningfulTextValidator.isValid('Available 24/7 for urgent repairs.'),
          isTrue,
        );
      });

      test('accepts text combined with normal punctuation', () {
        expect(
          MeaningfulTextValidator.isValid(
            'Emergency service - available 24/7.',
          ),
          isTrue,
        );
        expect(MeaningfulTextValidator.isValid('A & B Services'), isTrue);
        expect(
          MeaningfulTextValidator.isValid("O'Connor & Sons (est. 1990)"),
          isTrue,
        );
      });

      test('accepts text with Arabic diacritics', () {
        expect(MeaningfulTextValidator.isValid('مَرْحَبًا بكم'), isTrue);
      });

      test('accepts a single meaningful word alongside symbols', () {
        expect(MeaningfulTextValidator.isValid('!!! Sale !!!'), isTrue);
      });
    });
  });
}
