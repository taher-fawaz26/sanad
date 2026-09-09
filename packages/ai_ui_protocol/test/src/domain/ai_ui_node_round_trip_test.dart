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
  const callAhmed = AiUiAction(
    type: AiUiActionType.callPhone,
    params: {'phone': '+971501234567'},
  );
  const openMarina = AiUiAction(
    type: AiUiActionType.openMap,
    params: {'query': 'Dubai Marina, Tower 5'},
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
    'image (url and asset)': const AiUiImageNode(
      id: 'n4',
      source: AiUiImageSource(
        url: 'https://cdn.trysanad.us/services/ac.jpg',
        assetId: 'service_placeholder',
      ),
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
          leadingImage: AiUiImageSource.url(
            'https://cdn.trysanad.us/rows/order.jpg',
          ),
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
      image: AiUiImageSource(
        url: 'https://cdn.trysanad.us/services/ac.jpg',
        assetId: 'service_placeholder',
      ),
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
    'order_card': const AiUiOrderCardNode(
      id: 'n22',
      orderId: 'ord_1042',
      title: 'Order #1042',
      statusText: 'In progress',
      status: 'Active',
      statusTone: AiUiTone.success,
      amount: AiUiMoney(amount: 90, currency: 'AED'),
      action: openService,
      actions: [
        AiUiCardAction(
          label: 'Track',
          action: openService,
          variant: AiUiButtonVariant.outline,
        ),
      ],
      fallbackText: 'Order #1042 — in progress — AED 90',
    ),
    'provider_card': const AiUiProviderCardNode(
      id: 'n23',
      providerId: 'prv_1',
      name: 'Ahmed K.',
      roleText: 'AC and plumbing specialist',
      ratingValue: 4.8,
      image: AiUiImageSource.url(
        'https://cdn.trysanad.us/providers/ahmed.jpg',
      ),
      stats: [
        AiUiStat(label: 'Completed jobs', value: '340+'),
        AiUiStat(label: 'With CleanCo since', value: '2021'),
      ],
      action: openService,
      actions: [
        AiUiCardAction(
          label: 'Call',
          action: callAhmed,
          variant: AiUiButtonVariant.outline,
        ),
        AiUiCardAction(label: 'Message', action: sendYes),
      ],
      fallbackText: 'Ahmed K. — 4.8 — AC and plumbing specialist',
    ),
    'booking_summary': const AiUiBookingSummaryNode(
      id: 'n24',
      title: 'Booking summary',
      items: [
        AiUiDetailItem(label: 'Service', value: 'Deep Cleaning'),
        AiUiDetailItem(label: 'Provider', value: 'CleanCo Marina'),
        AiUiDetailItem(
          label: 'Estimated cost',
          value: '150 AED',
          valueTone: AiUiTone.primary,
        ),
      ],
      actions: [
        AiUiCardAction(
          label: 'Go back',
          action: sendYes,
          variant: AiUiButtonVariant.secondary,
          intent: AiUiButtonIntent.neutral,
        ),
        AiUiCardAction(label: 'Confirm', action: sendYes),
      ],
      fallbackText: 'Deep Cleaning with CleanCo Marina — 150 AED',
    ),
    'request_summary': const AiUiRequestSummaryNode(
      id: 'n25',
      items: [
        AiUiDetailItem(label: 'Service', value: 'Home Cleaning'),
        AiUiDetailItem(label: 'Date and time', value: 'Tomorrow, 10:00 AM'),
      ],
      summaryTitle: 'Summary',
      summaryText:
          'A full home clean, eco-friendly products, pet in the house.',
      location: AiUiLocationRef(
        addressText: 'Dubai Marina, Tower 5',
        label: 'Home',
        action: openMarina,
      ),
      actions: [
        AiUiCardAction(
          label: 'Cancel',
          action: sendYes,
          variant: AiUiButtonVariant.secondary,
          intent: AiUiButtonIntent.neutral,
        ),
        AiUiCardAction(label: 'Confirm', action: sendYes),
      ],
      fallbackText: 'Home Cleaning tomorrow at 10:00 AM',
    ),
    'payment_receipt': const AiUiPaymentReceiptNode(
      id: 'n26',
      title: 'Payment successful',
      subtitle: 'Thank you for your order',
      items: [
        AiUiDetailItem(
          label: 'Transaction ID',
          value: 'TXN-8829410',
          isLtrValue: true,
        ),
        AiUiDetailItem(label: 'Payment method', value: 'Apple Pay'),
      ],
      total: AiUiReceiptTotal(
        label: 'Amount paid',
        amount: AiUiMoney(amount: 150, currency: 'AED'),
      ),
      actions: [
        AiUiCardAction(
          label: 'View receipt',
          action: openService,
          variant: AiUiButtonVariant.outline,
        ),
      ],
      fallbackText: 'Payment successful — 150 AED',
    ),
    'time_slots': const AiUiTimeSlotsNode(
      id: 'n27',
      dateLabel: 'Tomorrow, September 3rd',
      slots: [
        AiUiTimeSlot(id: 's_0900', label: '9:00 AM'),
        AiUiTimeSlot(id: 's_1030', label: '10:30 AM'),
        AiUiTimeSlot(id: 's_1200', label: '12:00 PM', enabled: false),
      ],
      selectedSlotId: 's_0900',
      confirmLabel: 'Confirm time',
      confirmTemplate: 'Book me the {slot} slot',
      fallbackText: 'Slots tomorrow: 9:00 AM, 10:30 AM',
    ),
    'review_request': const AiUiReviewRequestNode(
      id: 'n28',
      serviceName: 'Deep Cleaning',
      providerText: 'Provided by CleanCo Marina',
      commentPlaceholder: 'Leave a comment (optional)',
      maxCommentLength: 300,
      submitLabel: 'Submit review',
      submitTemplate: 'My review of Deep Cleaning: {comment}',
      fallbackText: 'How was your Deep Cleaning service?',
    ),
    'location_picker': const AiUiLocationPickerNode(
      id: 'n29',
      title: 'Set your location',
      searchPlaceholder: 'Search for a neighbourhood or city',
      useCurrentLabel: 'Use current location',
      savedLabel: 'Saved locations',
      savedLocations: [
        AiUiSavedLocation(
          id: 'home',
          name: 'Home',
          addressText: 'Dubai Marina, Tower 5, Apt 1204',
          icon: 'fa-solid fa-house',
        ),
        AiUiSavedLocation(
          id: 'office',
          name: 'Office',
          addressText: 'DIFC, The Gate District, Level 4',
        ),
      ],
      confirmLabel: 'Confirm',
      confirmTemplate: 'Use {location} as my address',
      fallbackText: 'Where should the service happen?',
    ),
    'reminder_card': const AiUiReminderCardNode(
      id: 'n30',
      title: 'Reminder',
      subtitle: 'AC Maintenance',
      body: 'Your appointment is in 30 minutes.',
      actions: [
        AiUiCardAction(
          label: 'Reschedule',
          action: openService,
          variant: AiUiButtonVariant.outline,
        ),
        AiUiCardAction(label: "I'm ready", action: sendYes),
      ],
      fallbackText: 'Reminder: AC Maintenance in 30 minutes',
    ),
    'media_request': const AiUiMediaRequestNode(
      id: 'n31',
      title: 'Add photos or video',
      body: 'Sanad only asks for access when you pick one of these.',
      options: [
        AiUiMediaOption(label: 'Take a photo', source: AiUiMediaSource.camera),
        AiUiMediaOption(
          label: 'Choose photos',
          source: AiUiMediaSource.gallery,
        ),
        AiUiMediaOption(
          label: 'Add a short video',
          source: AiUiMediaSource.video,
        ),
      ],
      cancelLabel: 'Cancel',
      fallbackText: 'Add a photo or video of the problem',
    ),
    'permission_request': const AiUiPermissionRequestNode(
      id: 'n32',
      permission: AiUiPermissionKind.location,
      title: 'Allow location access',
      body: 'Sanad needs your location to find nearby services.',
      image: AiUiImageSource.asset('service_placeholder'),
      allowLabel: 'Allow while using the app',
      denyLabel: "Don't allow",
      fallbackText: 'Sanad needs your location to continue',
    ),
    'location_confirm': const AiUiLocationConfirmNode(
      id: 'n33',
      title: 'Confirm your location',
      image: AiUiImageSource.asset('service_placeholder'),
      addressText: 'Dubai Marina',
      confirmLabel: 'Confirm location',
      changeLabel: 'Change location',
      actions: [
        AiUiCardAction(label: 'Open in maps', action: openMarina),
      ],
      fallbackText: 'Is Dubai Marina the right address?',
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
