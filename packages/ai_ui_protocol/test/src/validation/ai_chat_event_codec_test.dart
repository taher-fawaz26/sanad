import 'dart:convert';

import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> envelope(
  String type, {
  String eventId = 'evt_1',
  String? messageId = 'msg_1',
  Map<String, dynamic>? payload,
  Object? seq,
  String? createdAt,
}) => <String, dynamic>{
  'eventId': eventId,
  if (messageId != null) 'messageId': messageId,
  'conversationId': 'conv_1',
  'type': type,
  if (seq != null) 'seq': seq,
  if (createdAt != null) 'createdAt': createdAt,
  if (payload != null) 'payload': payload,
};

AiChatEvent? decoded(Map<String, dynamic> json) {
  final result = AiChatEventCodec.decodeMap(json);
  return result is AiChatEventDecoded ? result.event : null;
}

void main() {
  group('envelope decoding', () {
    test('decodes message_start', () {
      final event = decoded(envelope('message_start'));

      expect(event, isA<AiChatMessageStartEvent>());
      expect(event!.messageId, 'msg_1');
      expect(event.conversationId, 'conv_1');
      expect((event as AiChatMessageStartEvent).role, 'assistant');
    });

    test('decodes text_delta', () {
      final event = decoded(
        envelope('text_delta', payload: {'delta': 'I found '}),
      );

      expect((event! as AiChatTextDeltaEvent).delta, 'I found ');
    });

    test('decodes message_end with authoritative text', () {
      final event = decoded(
        envelope('message_end', payload: {'text': 'I found 3 services.'}),
      );

      expect(
        (event! as AiChatMessageEndEvent).text,
        'I found 3 services.',
      );
    });

    test('decodes message_end with no text', () {
      final event = decoded(envelope('message_end'));

      expect(event, isA<AiChatMessageEndEvent>());
      expect((event! as AiChatMessageEndEvent).text, isNull);
    });

    test('decodes a ui event and leaves the payload unvalidated', () {
      // Validation needs host configuration (URL policy, the action registry's
      // real key set, known asset ids) that the envelope layer has no business
      // knowing, so the codec hands the raw object on.
      final event = decoded(
        envelope('ui', payload: {'schemaVersion': 1, 'blocks': <Object?>[]}),
      );

      expect((event! as AiChatUiEvent).payload['schemaVersion'], 1);
    });

    test('decodes typing', () {
      final active =
          decoded(
                envelope('typing', messageId: null, payload: {'active': true}),
              )!
              as AiChatTypingEvent;
      final idle =
          decoded(envelope('typing', messageId: null))! as AiChatTypingEvent;

      expect(active.active, isTrue);
      expect(idle.active, isFalse);
    });

    test('decodes error, defaulting the code', () {
      final event =
          decoded(
                envelope(
                  'error',
                  messageId: null,
                  payload: {'message': 'Try again'},
                ),
              )
              as AiChatErrorEvent?;

      expect(event!.code, 'unknown');
      expect(event.message, 'Try again');
    });

    test('parses seq and createdAt, normalising the instant to UTC', () {
      final event = decoded(
        envelope(
          'message_start',
          seq: 7,
          createdAt: '2026-08-31T13:00:00+04:00',
        ),
      );

      expect(event!.seq, 7);
      expect(event.createdAt, DateTime.utc(2026, 8, 31, 9));
    });

    test('defaults seq to 0 when absent or the wrong type', () {
      expect(decoded(envelope('message_start'))!.seq, 0);
      expect(decoded(envelope('message_start', seq: '3'))!.seq, 0);
    });
  });

  group('forward compatibility', () {
    test('ignores an unknown event type rather than failing', () {
      // `tool_status` is reserved in the spec and unimplemented here. An older
      // client must be able to skip it, so the backend can ship it first.
      final result = AiChatEventCodec.decodeMap(envelope('tool_status'));

      expect(result, isA<AiChatEventIgnored>());
      expect(
        (result as AiChatEventIgnored).diagnostic.code,
        AiUiDiagnosticCode.malformedPayload,
      );
    });

    test('ignores unknown envelope fields', () {
      final event = decoded(<String, dynamic>{
        ...envelope('message_start'),
        'traceId': 'abc',
        'model': 'some-model',
      });

      expect(event, isA<AiChatMessageStartEvent>());
    });
  });

  group('rejection', () {
    test('rejects a frame with no eventId', () {
      expect(
        AiChatEventCodec.decodeMap(<String, dynamic>{'type': 'typing'}),
        isA<AiChatEventIgnored>(),
      );
    });

    test('rejects message-scoped events with no messageId', () {
      for (final type in ['message_start', 'text_delta', 'message_end', 'ui']) {
        expect(
          AiChatEventCodec.decodeMap(
            envelope(type, messageId: null, payload: {'delta': 'x'}),
          ),
          isA<AiChatEventIgnored>(),
          reason: type,
        );
      }
    });

    test('rejects text_delta with a non-string delta', () {
      expect(
        AiChatEventCodec.decodeMap(
          envelope('text_delta', payload: {'delta': 42}),
        ),
        isA<AiChatEventIgnored>(),
      );
    });

    test('rejects a ui event with no payload', () {
      expect(
        AiChatEventCodec.decodeMap(envelope('ui')),
        isA<AiChatEventIgnored>(),
      );
    });
  });

  group('decode from a raw frame', () {
    test('decodes a JSON string', () {
      final result = AiChatEventCodec.decode(
        jsonEncode(envelope('text_delta', payload: {'delta': 'hi'})),
      );

      expect(result, isA<AiChatEventDecoded>());
    });

    test('ignores a truncated or non-JSON frame instead of throwing', () {
      for (final raw in ['', '{"eventId":', 'null', '[]', 'garbage']) {
        expect(
          () => AiChatEventCodec.decode(raw),
          returnsNormally,
          reason: raw,
        );
        expect(
          AiChatEventCodec.decode(raw),
          isA<AiChatEventIgnored>(),
          reason: raw,
        );
      }
    });

    test('ignores an oversized frame', () {
      final raw = jsonEncode(
        envelope('text_delta', payload: {'delta': 'x' * 100}),
      );

      expect(
        AiChatEventCodec.decode(
          raw,
          limits: const AiUiLimits(maxPayloadBytes: 32),
        ),
        isA<AiChatEventIgnored>(),
      );
    });
  });

  group('serialization', () {
    test('every event round-trips through toJson', () {
      final events = <AiChatEvent>[
        const AiChatMessageStartEvent(eventId: 'e1', messageId: 'm1'),
        const AiChatTextDeltaEvent(
          eventId: 'e2',
          messageId: 'm1',
          delta: 'hello',
        ),
        const AiChatMessageEndEvent(
          eventId: 'e3',
          messageId: 'm1',
          text: 'hello there',
        ),
        const AiChatUiEvent(
          eventId: 'e4',
          messageId: 'm1',
          payload: {'schemaVersion': 1, 'blocks': <Object?>[]},
        ),
        const AiChatTypingEvent(eventId: 'e5', active: true),
        const AiChatErrorEvent(eventId: 'e6', code: 'rate_limited'),
      ];

      for (final event in events) {
        final result = AiChatEventCodec.decodeMap(event.toJson());
        expect(result, isA<AiChatEventDecoded>(), reason: '${event.type}');
        expect(
          (result as AiChatEventDecoded).event,
          equals(event),
          reason: '${event.type}',
        );
      }
    });

    test('covers every event type', () {
      expect(AiChatEventType.values, hasLength(6));
    });
  });
}
