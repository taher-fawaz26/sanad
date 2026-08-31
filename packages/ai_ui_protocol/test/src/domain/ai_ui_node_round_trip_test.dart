import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/protocol_test_support.dart';

/// Round-trips every node type through `toJson()` and back through the real
/// validator.
///
/// This is stronger than a plain `fromJson`/`toJson` pair: it proves the
/// serialized form of a node is something the *validator* accepts, so a node
/// the app builds and a node the agent sends are the same thing. It also
/// catches the easy mistake of adding a field to a model and forgetting it in
/// one of the two directions.
void main() {
  const openService = AiUiAction(
    type: AiUiActionType.openService,
    params: {'serviceId': 's1'},
  );
  const sendYes = AiUiAction(
    type: AiUiActionType.sendMessage,
    params: {'text': 'Yes'},
  );

  final cases = <String, AiUiNode>{
    'text': const AiUiTextNode(
      id: 'n1',
      text: 'Your appointment is confirmed',
      style: AiUiTextStyleToken.title,
      emphasis: AiUiEmphasis.strong,
      align: AiUiMainAxisAlign.center,
      direction: AiUiTextDirectionHint.ltrValue,
      maxLines: 3,
      a11yLabel: 'Confirmation heading',
      fallbackText: 'Confirmed',
    ),
    'rich_text': const AiUiRichTextNode(
      id: 'n2',
      spans: [
        AiUiRichSpan(text: 'Tap '),
        AiUiRichSpan(
          text: 'here',
          emphasis: AiUiEmphasis.strong,
          action: openService,
        ),
      ],
      align: AiUiMainAxisAlign.end,
    ),
    'icon': const AiUiIconNode(
      id: 'n3',
      name: 'fa-solid fa-calendar',
      size: AiUiIconSize.lg,
      tone: AiUiTone.success,
    ),
    'image (asset)': const AiUiImageNode(
      id: 'n4',
      source: AiUiAssetImage('service_placeholder'),
      alt: 'Service illustration',
      aspect: AiUiImageAspect.square,
      fit: AiUiImageFit.contain,
    ),
    'divider': const AiUiDividerNode(id: 'n6', spacing: AiUiSpacingStep.lg),
    'spacer': const AiUiSpacerNode(id: 'n7', size: AiUiSpacingStep.xl),
    'row': const AiUiRowNode(
      id: 'n8',
      children: [AiUiTextNode(id: 'n8a', text: 'left')],
      align: AiUiMainAxisAlign.spaceBetween,
      crossAlign: AiUiCrossAxisAlign.end,
      gap: AiUiSpacingStep.lg,
      wrap: true,
    ),
    'column': const AiUiColumnNode(
      id: 'n9',
      children: [AiUiTextNode(id: 'n9a', text: 'top')],
      align: AiUiCrossAxisAlign.center,
      gap: AiUiSpacingStep.xs,
    ),
    'card': const AiUiCardNode(
      id: 'n10',
      children: [AiUiTextNode(id: 'n10a', text: 'Tomorrow at 10:00 AM')],
      title: 'Appointment',
      tone: AiUiTone.info,
      action: openService,
    ),
    'button': const AiUiButtonNode(
      id: 'n11',
      label: 'View appointment',
      action: openService,
      variant: AiUiButtonVariant.outline,
      intent: AiUiButtonIntent.destructive,
      size: AiUiButtonSize.small,
      icon: 'fa-solid fa-eye',
      enabled: false,
    ),
    'chip': const AiUiChipNode(
      id: 'n12',
      label: 'Popular',
      action: sendYes,
      selected: true,
      tone: AiUiTone.info,
      icon: 'fa-solid fa-star',
    ),
    'list': const AiUiListNode(
      id: 'n13',
      children: [
        AiUiListItemNode(
          id: 'n13a',
          title: 'Downtown branch',
          subtitle: 'Sheikh Zayed Road',
          leadingIcon: 'fa-solid fa-store',
          leadingImage: AiUiAssetImage('service_placeholder'),
          badge: AiUiBadge(label: 'Open', tone: AiUiTone.success),
          trailingText: '1.2 km',
          action: openService,
        ),
      ],
      variant: AiUiListVariant.sectioned,
      emptyText: 'No branches',
    ),
    'list_item': const AiUiListItemNode(
      id: 'n21',
      title: 'Marina branch',
      subtitle: 'Dubai Marina',
      badge: AiUiBadge(label: 'Closed', tone: AiUiTone.error),
      trailingText: '4.8 km',
    ),
    'progress': const AiUiProgressNode(id: 'n14', value: 0.4, label: 'Booking'),
    'loading': const AiUiLoadingNode(id: 'n15', label: 'Thinking'),
    'service_card': const AiUiServiceCardNode(
      id: 'n16',
      serviceId: 'svc_123',
      title: 'AC Maintenance',
      subtitle: 'Same-day service',
      price: AiUiMoney(amount: 100, currency: 'AED'),
      ratingValue: 4.5,
      image: AiUiAssetImage('service_placeholder'),
      badge: AiUiBadge(label: 'Popular', tone: AiUiTone.info),
      action: openService,
      fallbackText: 'AC Maintenance — 100 AED',
    ),
    'appointment_card': AiUiAppointmentCardNode(
      id: 'n17',
      appointmentId: 'apt_1',
      title: 'AC Maintenance',
      startsAt: DateTime.utc(2026, 9, 1, 6, 30),
      whereText: 'Downtown branch',
      status: 'Confirmed',
      statusTone: AiUiTone.success,
      action: openService,
    ),
    'branch_card': const AiUiBranchCardNode(
      id: 'n18',
      branchId: 'br_1',
      name: 'Downtown',
      addressText: 'Sheikh Zayed Road',
      distanceMeters: 1200,
      status: 'Open',
      statusTone: AiUiTone.success,
      action: openService,
    ),
    'document_card': const AiUiDocumentCardNode(
      id: 'n19',
      documentId: 'doc_1',
      title: 'Trade licence',
      status: 'Expiring soon',
      statusTone: AiUiTone.warning,
      action: openService,
    ),
    'quick_reply': const AiUiQuickReplyNode(
      id: 'n20',
      options: [
        AiUiQuickReplyOption(label: 'Yes', action: sendYes),
        AiUiQuickReplyOption(
          label: 'No',
          action: AiUiAction(
            type: AiUiActionType.sendMessage,
            params: {'text': 'No'},
          ),
        ),
      ],
    ),
  };

  group('node round-trips through toJson + validate', () {
    cases.forEach((name, node) {
      test(name, () {
        final result = validatorWith(
          knownAssetIds: const {'service_placeholder'},
        ).validate(payload([node.toJson()]));

        expect(
          result.diagnostics,
          isEmpty,
          reason: 'round-tripping $name produced ${result.diagnostics}',
        );
        expect(result.document!.blocks.single, equals(node));
      });
    });

    test('covers every node type in the catalog', () {
      // Guards against adding a node type and forgetting to round-trip it.
      final covered = cases.values.map((n) => n.type).nonNulls.toSet();
      expect(covered, equals(AiUiNodeType.values.toSet()));
    });
  });

  group('AiUiUnsupportedNode', () {
    test('round-trips its raw type when unsupported nodes are kept', () {
      const node = AiUiUnsupportedNode(id: 'u1', rawType: 'future_component');

      final result = validatorWith(
        keepUnsupportedNodes: true,
      ).validate(payload([node.toJson()]));

      expect(result.document!.blocks.single, equals(node));
    });
  });

  group('AiUiDocument', () {
    test('counts nested nodes', () {
      const document = AiUiDocument(
        schemaVersion: 1,
        blocks: [
          AiUiColumnNode(
            id: 'c',
            children: [
              AiUiTextNode(id: 't1', text: 'a'),
              AiUiRowNode(
                id: 'r',
                children: [AiUiTextNode(id: 't2', text: 'b')],
              ),
            ],
          ),
        ],
      );

      expect(document.nodeCount, 4);
    });

    test('a document survives a full JSON round-trip', () {
      const original = AiUiDocument(
        schemaVersion: 1,
        blocks: [
          AiUiTextNode(id: 't', text: 'I found 3 services near you.'),
          AiUiQuickReplyNode(
            id: 'q',
            options: [
              AiUiQuickReplyOption(label: 'Yes', action: sendYes),
              AiUiQuickReplyOption(
                label: 'No',
                action: AiUiAction(
                  type: AiUiActionType.sendMessage,
                  params: {'text': 'No'},
                ),
              ),
            ],
          ),
        ],
      );

      final result = validatorWith().validate(original.toJson());

      expect(result.document, equals(original));
    });
  });
}
