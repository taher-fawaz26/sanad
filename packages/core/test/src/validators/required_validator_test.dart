import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('RequiredValidator', () {
    group('isValid', () {
      test('accepts non-empty string', () {
        expect(RequiredValidator.isValid('hello'), isTrue);
      });

      test(
        'accepts string with leading/trailing whitespace around content',
        () {
          expect(RequiredValidator.isValid('  hello  '), isTrue);
        },
      );

      test('rejects null', () {
        expect(RequiredValidator.isValid(null), isFalse);
      });

      test('rejects empty string', () {
        expect(RequiredValidator.isValid(''), isFalse);
      });

      test('rejects whitespace-only string', () {
        expect(RequiredValidator.isValid('   '), isFalse);
        expect(RequiredValidator.isValid('\t\n'), isFalse);
      });
    });
  });
}
