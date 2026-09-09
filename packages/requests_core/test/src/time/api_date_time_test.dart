import 'package:flutter_test/flutter_test.dart';
import 'package:requests_core/requests_core.dart';

void main() {
  group('ApiDateTime.encode', () {
    test('always emits an explicit offset for a LOCAL DateTime', () {
      // The regression this pins: `DateTime.toIso8601String()` on a local
      // value emits "2026-09-12T10:00:00.000" with no zone, which the backend
      // reads as UTC — four hours out in Gulf Standard Time.
      final local = DateTime(2026, 9, 12, 10);
      expect(local.isUtc, isFalse);
      expect(local.toIso8601String(), isNot(endsWith('Z')));
      expect(ApiDateTime.encode(local), endsWith('Z'));
    });

    test('preserves the instant across the UTC normalisation', () {
      final local = DateTime(2026, 9, 12, 10);
      expect(DateTime.parse(ApiDateTime.encode(local)), local.toUtc());
    });

    test('leaves an already-UTC value on the same instant', () {
      final utc = DateTime.utc(2026, 9, 12, 6);
      expect(ApiDateTime.encode(utc), '2026-09-12T06:00:00.000Z');
    });

    test('encodeNullable passes null through', () {
      expect(ApiDateTime.encodeNullable(null), isNull);
    });
  });

  group('ApiDateTime.decode', () {
    test('reads a +04:00 offset as the correct instant', () {
      final parsed = ApiDateTime.decode('2026-09-12T10:00:00+04:00');
      expect(parsed, isNotNull);
      expect(parsed!.toUtc(), DateTime.utc(2026, 9, 12, 6));
    });

    test('reads a Z instant', () {
      expect(
        ApiDateTime.decode('2026-09-12T06:00:00.000Z')!.toUtc(),
        DateTime.utc(2026, 9, 12, 6),
      );
    });

    test('returns null for absent or malformed input rather than throwing', () {
      expect(ApiDateTime.decode(null), isNull);
      expect(ApiDateTime.decode(''), isNull);
      expect(ApiDateTime.decode('not a date'), isNull);
      expect(ApiDateTime.decode(42), isNull);
    });
  });
}
