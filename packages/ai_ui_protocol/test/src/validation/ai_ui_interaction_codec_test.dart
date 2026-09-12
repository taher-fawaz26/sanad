import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('decoding rejects', () {
    test('anything that is not a JSON object', () {
      for (final raw in ['', 'null', '[]', '"text"', '{', 'not json']) {
        expect(AiUiInteractionCodec.tryDecode(raw), isNull, reason: raw);
      }
    });

    test('a result with no idempotency key', () {
      expect(
        AiUiInteractionCodec.tryDecodeMap(const {
          'nodeId': 'n',
          'kind': 'slot_selected',
        }),
        isNull,
      );
    });

    test('a result that names no node', () {
      expect(
        AiUiInteractionCodec.tryDecodeMap(const {
          'interactionId': 'i',
          'kind': 'slot_selected',
        }),
        isNull,
      );
    });

    test('an unknown kind — this build cannot reason about it', () {
      expect(
        AiUiInteractionCodec.tryDecodeMap(const {
          'interactionId': 'i',
          'nodeId': 'n',
          'kind': 'signature_captured',
        }),
        isNull,
      );
    });

    test('an unknown status rather than assuming the user answered', () {
      expect(
        AiUiInteractionCodec.tryDecodeMap(const {
          'interactionId': 'i',
          'nodeId': 'n',
          'kind': 'slot_selected',
          'status': 'deferred',
        }),
        isNull,
      );
    });
  });

  group('decoding degrades', () {
    test('a missing status to submitted', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'kind': 'slot_selected',
        'value': {'label': '09:00'},
      });

      expect(decoded?.status, AiUiInteractionStatus.submitted);
    });

    test('a value of the wrong shape to empty, keeping the result', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'kind': 'slot_selected',
        'value': {'unexpected': true},
      });

      expect(decoded, isNotNull);
      expect(decoded!.value, const AiUiEmptyValue());
      expect(decoded.kind, AiUiInteractionKind.slotSelected);
    });

    test('a non-object value to empty', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'kind': 'review_submitted',
        'value': 'oops',
      });

      expect(decoded?.value, const AiUiEmptyValue());
    });

    test('an unknown permission outcome to empty', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'kind': 'permission_result',
        'value': {'permission': 'camera', 'outcome': 'maybe'},
      });

      expect(decoded?.value, const AiUiEmptyValue());
    });

    test('an unknown node type to null without losing the result', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'nodeType': 'signature_pad',
        'kind': 'slot_selected',
        'value': {'label': '09:00'},
      });

      expect(decoded, isNotNull);
      expect(decoded!.nodeType, isNull);
    });

    test('an unknown location source to typed', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'kind': 'location_selected',
        'value': {'name': 'Marina', 'source': 'satellite'},
      });

      expect(
        decoded?.value,
        const AiUiLocationValue(
          name: 'Marina',
          source: AiUiLocationSource.typed,
        ),
      );
    });
  });

  group('clamping', () {
    const limits = AiUiLimits(maxInteractionTextLength: 8);

    test('caps the prose that reaches the agent', () {
      const interaction = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'n',
        kind: AiUiInteractionKind.reviewSubmitted,
        value: AiUiEmptyValue(),
        text: 'far longer than eight',
      );

      expect(
        AiUiInteractionCodec.encodeMap(interaction, limits: limits)['text'],
        'far long',
      );
    });

    test('caps a typed comment', () {
      const interaction = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'n',
        kind: AiUiInteractionKind.reviewSubmitted,
        value: AiUiTextValue('far longer than eight'),
      );

      final value = AiUiInteractionCodec.encodeMap(
        interaction,
        limits: limits,
      )['value'];

      expect(value, const {'text': 'far long'});
    });

    test('caps an unbounded typed location query', () {
      const interaction = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'n',
        kind: AiUiInteractionKind.locationSelected,
        value: AiUiLocationValue(
          name: 'far longer than eight',
          source: AiUiLocationSource.typed,
        ),
      );

      final value = AiUiInteractionCodec.encodeMap(
        interaction,
        limits: limits,
      )['value'];

      expect(value, const {'name': 'far long', 'source': 'typed'});
    });

    test('leaves a value that fits untouched', () {
      const interaction = AiUiInteraction(
        interactionId: 'i',
        nodeId: 'n',
        kind: AiUiInteractionKind.slotSelected,
        value: AiUiSelectionValue(label: '09:00'),
        text: 'ok',
      );

      expect(
        AiUiInteractionCodec.encodeMap(interaction, limits: limits),
        AiUiInteractionCodec.encodeMap(interaction),
      );
    });

    test('rejects a payload larger than the size limit', () {
      final huge = '{"interactionId":"i","nodeId":"${'n' * 40000}"}';

      expect(AiUiInteractionCodec.tryDecode(huge), isNull);
    });
  });

  group('totality', () {
    test('no adversarial input throws', () {
      final inputs = <Map<String, dynamic>>[
        const {},
        const {'interactionId': 1, 'nodeId': 2, 'kind': 3},
        const {'interactionId': '', 'nodeId': '', 'kind': ''},
        const {
          'interactionId': 'i',
          'nodeId': 'n',
          'kind': 'media_result',
          'value': {'count': 'two'},
        },
        const {
          'interactionId': 'i',
          'nodeId': 'n',
          'kind': 'slot_selected',
          'createdAt': 'not-a-date',
          'value': {'label': 'x'},
        },
      ];

      for (final input in inputs) {
        expect(
          () => AiUiInteractionCodec.tryDecodeMap(input),
          returnsNormally,
          reason: '$input',
        );
      }
    });

    test('an unparseable createdAt drops the timestamp, not the result', () {
      final decoded = AiUiInteractionCodec.tryDecodeMap(const {
        'interactionId': 'i',
        'nodeId': 'n',
        'kind': 'slot_selected',
        'createdAt': 'not-a-date',
        'value': {'label': 'x'},
      });

      expect(decoded, isNotNull);
      expect(decoded!.createdAt, isNull);
    });
  });

  group('AiUiLimits equality', () {
    test('covers every field, including the newest ones', () {
      const base = AiUiLimits.defaults;

      // Every assertion below is an inequality, and each one only holds
      // because the field it varies is in `props`. Before this change the
      // eight newest fields were missing from that list, so a validator
      // configured with a different slot cap compared equal to the default.
      expect(base, AiUiLimits.defaults);
      expect(base, isNot(const AiUiLimits(maxCardActions: 1)));
      expect(base, isNot(const AiUiLimits(maxDetailItems: 1)));
      expect(base, isNot(const AiUiLimits(maxTimeSlots: 1)));
      expect(base, isNot(const AiUiLimits(minTimeSlots: 1)));
      expect(base, isNot(const AiUiLimits(maxSavedLocations: 1)));
      expect(base, isNot(const AiUiLimits(maxMediaOptions: 1)));
      expect(base, isNot(const AiUiLimits(maxStats: 1)));
      expect(base, isNot(const AiUiLimits(maxCommentLength: 1)));
      expect(base, isNot(const AiUiLimits(maxInteractionTextLength: 1)));
    });
  });
}
