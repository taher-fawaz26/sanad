import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiUiCodec.decode', () {
    test('decodes a well-formed object', () {
      final result = AiUiCodec.decode('{"schemaVersion":1,"blocks":[]}');

      expect(result, isA<AiUiDecodeSuccess>());
      expect((result as AiUiDecodeSuccess).json['schemaVersion'], 1);
    });

    test('rejects invalid JSON without throwing', () {
      final result = AiUiCodec.decode('{"schemaVersion":1,');

      expect(result, isA<AiUiDecodeFailure>());
      expect(
        (result as AiUiDecodeFailure).diagnostic.code,
        AiUiDiagnosticCode.malformedPayload,
      );
    });

    test('rejects a non-object root', () {
      for (final raw in ['[]', '"text"', '42', 'null', 'true']) {
        final result = AiUiCodec.decode(raw);
        expect(result, isA<AiUiDecodeFailure>(), reason: 'for input $raw');
        expect(
          (result as AiUiDecodeFailure).diagnostic.code,
          AiUiDiagnosticCode.malformedPayload,
          reason: 'for input $raw',
        );
      }
    });

    test('rejects an empty string', () {
      expect(AiUiCodec.decode(''), isA<AiUiDecodeFailure>());
    });

    test('rejects a payload over the byte limit', () {
      const limits = AiUiLimits(maxPayloadBytes: 64);
      final oversized =
          '{"schemaVersion":1,"blocks":[],"pad":"'
          '${'x' * 200}"}';

      final result = AiUiCodec.decode(oversized, limits: limits);

      expect(result, isA<AiUiDecodeFailure>());
      expect(
        (result as AiUiDecodeFailure).diagnostic.code,
        AiUiDiagnosticCode.limitExceeded,
      );
    });

    test('measures size in UTF-8 bytes, not code units', () {
      // Arabic is 2 bytes per character in UTF-8. 40 characters is 80 bytes,
      // which must trip a 64-byte limit even though String.length is 40 —
      // the wire counts bytes, so the guard has to as well.
      final arabic = 'ن' * 40;
      final raw = '{"schemaVersion":1,"blocks":[],"pad":"$arabic"}';

      expect(raw.length, lessThan(120));
      expect(
        AiUiCodec.decode(raw, limits: const AiUiLimits(maxPayloadBytes: 64)),
        isA<AiUiDecodeFailure>(),
      );
    });
  });
}
