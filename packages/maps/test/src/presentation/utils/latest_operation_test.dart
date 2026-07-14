import 'package:flutter_test/flutter_test.dart';
import 'package:maps/src/presentation/utils/latest_operation.dart';

void main() {
  group('LatestOperation', () {
    test('a freshly started operation is current', () {
      final op = LatestOperation();
      final token = op.begin();
      expect(op.isCurrent(token), isTrue);
    });

    test('an older operation is no longer current after a newer begin', () {
      final op = LatestOperation();
      final first = op.begin();
      final second = op.begin();

      expect(op.isCurrent(first), isFalse);
      expect(op.isCurrent(second), isTrue);
    });

    test('tokens are unique and monotonic', () {
      final op = LatestOperation();
      final a = op.begin();
      final b = op.begin();
      final c = op.begin();

      expect(a, isNot(b));
      expect(b, isNot(c));
      expect(op.isCurrent(a), isFalse);
      expect(op.isCurrent(b), isFalse);
      expect(op.isCurrent(c), isTrue);
    });
  });
}
