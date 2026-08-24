import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('FileSizePolicy', () {
    test('maxBytes is exactly 5 MiB', () {
      expect(FileSizePolicy.maxBytes, 5 * 1024 * 1024);
    });

    group('isValid', () {
      test('accepts a size exactly at the maximum', () {
        expect(FileSizePolicy.isValid(FileSizePolicy.maxBytes), isTrue);
      });

      test('accepts a size one byte under the maximum', () {
        expect(FileSizePolicy.isValid(FileSizePolicy.maxBytes - 1), isTrue);
      });

      test('rejects a size one byte over the maximum', () {
        expect(FileSizePolicy.isValid(FileSizePolicy.maxBytes + 1), isFalse);
      });

      test('rejects a clearly oversized file (7 MB)', () {
        expect(FileSizePolicy.isValid(7 * 1024 * 1024), isFalse);
      });
    });

    group('effectiveLimit', () {
      test('returns the global maximum when no feature limit is given', () {
        expect(FileSizePolicy.effectiveLimit(), FileSizePolicy.maxBytes);
      });

      test(
        'returns the global maximum when the feature limit is looser — a '
        'feature-specific rule may never exceed the global cap',
        () {
          expect(
            FileSizePolicy.effectiveLimit(10 * 1024 * 1024),
            FileSizePolicy.maxBytes,
          );
        },
      );

      test('returns the feature limit when it is stricter (smaller)', () {
        expect(FileSizePolicy.effectiveLimit(1024 * 1024), 1024 * 1024);
      });

      test('returns the feature limit unchanged when it equals the global '
          'maximum', () {
        expect(
          FileSizePolicy.effectiveLimit(FileSizePolicy.maxBytes),
          FileSizePolicy.maxBytes,
        );
      });
    });
  });
}
