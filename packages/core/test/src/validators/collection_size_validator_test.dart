import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('CollectionSizeValidator', () {
    group('isValid', () {
      test('accepts a count within min and max bounds', () {
        expect(
          CollectionSizeValidator.isValid(3, minItems: 1, maxItems: 6),
          isTrue,
        );
      });

      test('accepts a count exactly at the minimum boundary', () {
        expect(CollectionSizeValidator.isValid(1, minItems: 1), isTrue);
      });

      test('rejects a count one below the minimum', () {
        expect(CollectionSizeValidator.isValid(0, minItems: 1), isFalse);
      });

      test('accepts a count exactly at the maximum boundary', () {
        expect(CollectionSizeValidator.isValid(6, maxItems: 6), isTrue);
      });

      test('rejects a count one above the maximum', () {
        expect(CollectionSizeValidator.isValid(7, maxItems: 6), isFalse);
      });

      test('treats null as zero', () {
        expect(CollectionSizeValidator.isValid(null, minItems: 1), isFalse);
        expect(CollectionSizeValidator.isValid(null, maxItems: 6), isTrue);
      });

      test('is a no-op when neither bound is provided', () {
        expect(CollectionSizeValidator.isValid(100), isTrue);
        expect(CollectionSizeValidator.isValid(null), isTrue);
      });
    });
  });
}
