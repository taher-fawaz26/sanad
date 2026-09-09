import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

/// One interaction per kind, so the table below can be asserted exhaustive
/// against the enum the same way `ai_ui_node_round_trip_test.dart` is asserted
/// against `AiUiNodeType`. A kind added without a fixture fails the coverage
/// test rather than silently going unserialised.
final Map<AiUiInteractionKind, AiUiInteraction> _fixtures = {
  AiUiInteractionKind.quickReplySelected: const AiUiInteraction(
    interactionId: 'int_1',
    nodeId: 'qr_1',
    nodeType: AiUiNodeType.quickReply,
    messageId: 'msg_1',
    kind: AiUiInteractionKind.quickReplySelected,
    value: AiUiSelectionValue(label: 'Yes, book it'),
    text: 'Yes, book it',
  ),
  AiUiInteractionKind.slotSelected: const AiUiInteraction(
    interactionId: 'int_2',
    nodeId: 'slots_1',
    nodeType: AiUiNodeType.timeSlots,
    messageId: 'msg_2',
    kind: AiUiInteractionKind.slotSelected,
    value: AiUiSelectionValue(id: 's_09', label: '09:00 AM'),
    text: 'Book me for 09:00 AM',
  ),
  AiUiInteractionKind.reviewSubmitted: const AiUiInteraction(
    interactionId: 'int_3',
    nodeId: 'review_1',
    nodeType: AiUiNodeType.reviewRequest,
    kind: AiUiInteractionKind.reviewSubmitted,
    value: AiUiTextValue('This was very good'),
    text: 'My review: This was very good',
  ),
  AiUiInteractionKind.locationSelected: const AiUiInteraction(
    interactionId: 'int_4',
    nodeId: 'loc_1',
    nodeType: AiUiNodeType.locationPicker,
    kind: AiUiInteractionKind.locationSelected,
    value: AiUiLocationValue(
      id: 'home',
      name: 'Home',
      addressText: 'Marina Tower 3, Dubai',
      source: AiUiLocationSource.saved,
    ),
    text: 'Use this location: Home',
  ),
  AiUiInteractionKind.locationConfirmed: const AiUiInteraction(
    interactionId: 'int_5',
    nodeId: 'confirm_1',
    nodeType: AiUiNodeType.locationConfirm,
    kind: AiUiInteractionKind.locationConfirmed,
    value: AiUiLocationValue(
      name: 'Marina Tower 3, Dubai',
      source: AiUiLocationSource.typed,
    ),
  ),
  AiUiInteractionKind.permissionResult: const AiUiInteraction(
    interactionId: 'int_6',
    nodeId: 'perm_1',
    nodeType: AiUiNodeType.permissionRequest,
    kind: AiUiInteractionKind.permissionResult,
    value: AiUiPermissionValue(
      permission: 'camera',
      outcome: AiUiPermissionOutcome.granted,
    ),
    text: 'camera: granted',
  ),
  AiUiInteractionKind.mediaResult: const AiUiInteraction(
    interactionId: 'int_7',
    nodeId: 'media_1',
    nodeType: AiUiNodeType.mediaRequest,
    kind: AiUiInteractionKind.mediaResult,
    value: AiUiMediaValue(count: 2, source: 'gallery'),
  ),
};

void main() {
  group('round trip', () {
    for (final entry in _fixtures.entries) {
      test('${entry.key.wire} survives encode then decode', () {
        final decoded = AiUiInteractionCodec.tryDecode(
          AiUiInteractionCodec.encode(entry.value),
        );

        expect(decoded, entry.value);
      });
    }

    test('every kind has a fixture', () {
      expect(_fixtures.keys.toSet(), AiUiInteractionKind.values.toSet());
    });

    test('every value subtype is covered by the fixtures', () {
      final types = _fixtures.values.map((i) => i.value.runtimeType).toSet();

      expect(
        types,
        containsAll(<Type>[
          AiUiSelectionValue,
          AiUiTextValue,
          AiUiLocationValue,
          AiUiPermissionValue,
          AiUiMediaValue,
        ]),
      );
    });

    test('an empty value round-trips on any kind', () {
      const interaction = AiUiInteraction(
        interactionId: 'int_8',
        nodeId: 'slots_1',
        kind: AiUiInteractionKind.slotSelected,
        status: AiUiInteractionStatus.cancelled,
        value: AiUiEmptyValue(),
      );

      expect(
        AiUiInteractionCodec.tryDecode(
          AiUiInteractionCodec.encode(interaction),
        ),
        interaction,
      );
    });

    test('createdAt is normalised to UTC', () {
      final interaction = AiUiInteraction(
        interactionId: 'int_9',
        nodeId: 'n',
        kind: AiUiInteractionKind.reviewSubmitted,
        value: const AiUiTextValue('hi'),
        createdAt: DateTime.utc(2026, 5, 4, 3, 2, 1),
      );

      final json = AiUiInteractionCodec.encodeMap(interaction);

      expect(json['createdAt'], '2026-05-04T03:02:01.000Z');
      expect(
        AiUiInteractionCodec.tryDecodeMap(json)?.createdAt,
        DateTime.utc(2026, 5, 4, 3, 2, 1),
      );
    });
  });

  group('the wire shape', () {
    test('omits every optional field it does not have', () {
      const interaction = AiUiInteraction(
        interactionId: 'int_10',
        nodeId: 'n_1',
        kind: AiUiInteractionKind.slotSelected,
        value: AiUiSelectionValue(label: '09:00'),
      );

      expect(AiUiInteractionCodec.encodeMap(interaction), {
        'interactionId': 'int_10',
        'nodeId': 'n_1',
        'kind': 'slot_selected',
        'status': 'submitted',
        'value': {'label': '09:00'},
      });
    });

    test('names the node type and the message that asked', () {
      final json = AiUiInteractionCodec.encodeMap(
        _fixtures[AiUiInteractionKind.slotSelected]!,
      );

      expect(json['nodeType'], 'time_slots');
      expect(json['messageId'], 'msg_2');
      expect(json['nodeId'], 'slots_1');
    });

    test('withStatus keeps the idempotency key', () {
      final original = _fixtures[AiUiInteractionKind.slotSelected]!;
      final failed = original.withStatus(AiUiInteractionStatus.failed);

      expect(failed.interactionId, original.interactionId);
      expect(failed.status, AiUiInteractionStatus.failed);
      expect(failed.isSubmitted, isFalse);
      expect(original.isSubmitted, isTrue);
    });
  });
}
