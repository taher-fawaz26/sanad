import 'package:design_system/design_system.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('String.ltrIsolated', () {
    // U+2066 LEFT-TO-RIGHT ISOLATE … U+2069 POP DIRECTIONAL ISOLATE.
    const lri = '\u{2066}';
    const pdi = '\u{2069}';

    test('wraps the value in an LTR isolate (SAN-770/771/775)', () {
      expect('+971585555552'.ltrIsolated, '$lri+971585555552$pdi');
    });

    test('works for emails and URLs too', () {
      expect('a@b.com'.ltrIsolated, '${lri}a@b.com$pdi');
      expect('https://x.co'.ltrIsolated, '${lri}https://x.co$pdi');
    });

    test('is a pure wrap — the original value is preserved verbatim', () {
      const value = 'anything at all';
      final wrapped = value.ltrIsolated;
      expect(wrapped.substring(1, wrapped.length - 1), value);
    });

    test('an empty string wraps to just the isolate markers', () {
      expect(''.ltrIsolated, '$lri$pdi');
    });
  });
}
