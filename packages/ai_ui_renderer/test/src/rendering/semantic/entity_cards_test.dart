import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

void main() {
  group('service_card', () {
    testWidgets('renders title, subtitle and badge', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'subtitle': 'Same-day service',
          'badge': {'label': 'Popular', 'tone': 'info'},
        },
      ]);

      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Same-day service'), findsOneWidget);
      expect(find.byType(AiCardBadge), findsOneWidget);
    });

    testWidgets('formats the structured price client-side', (tester) async {
      // The agent sends {amount, currency}; the client decides how a dirham
      // looks. That is the whole reason price is not pre-formatted prose.
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 100, 'currency': 'AED'},
        },
      ]);

      // Exact, not "contains": the separator between the code and the digits
      // is the part Figma specifies and the part `NumberFormat.currency`
      // would otherwise drop ("AED100").
      expect(find.text('AED 100'), findsOneWidget);
    });

    testWidgets('drops trailing zeros on whole amounts', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 100, 'currency': 'AED'},
        },
      ]);

      expect(find.textContaining('100.00'), findsNothing);
    });

    testWidgets('puts a single action on the price row', (tester) async {
      // Figma's `service-card` pairs the price with one compact pill rather
      // than a full-width button under it. Two or more actions still get
      // their own row, which is what AiCardActionRow is for.
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 100, 'currency': 'AED'},
          'actions': [
            {
              'label': 'Select',
              'variant': 'secondary',
              'action': {'type': 'send_message', 'text': 'That one'},
            },
          ],
        },
      ]);

      expect(find.text('Select'), findsOneWidget);
      expect(find.byType(AiCardActionRow), findsNothing);
      expect(
        tester.getTopLeft(find.text('Select')).dy,
        closeTo(tester.getTopLeft(find.text('AED 100')).dy, 12),
      );
    });

    testWidgets('keeps two digits on a fractional amount', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'price': {'amount': 99.5, 'currency': 'AED'},
        },
      ]);

      expect(find.textContaining('99.50'), findsOneWidget);
    });

    testWidgets('dispatches its action when tapped', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'service_card',
          'id': 's',
          'serviceId': 'svc_123',
          'title': 'AC Maintenance',
          'action': {'type': 'open_service', 'serviceId': 'svc_123'},
        },
      ]);

      await tester.tap(find.byType(InkWell));
      await tester.pump();

      expect(
        harness.callsTo(AiUiActionType.openService).single.serviceId,
        'svc_123',
      );
    });
  });

  group('appointment_card', () {
    testWidgets('formats the UTC instant in local time', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'appointment_card',
          'id': 'a',
          'appointmentId': 'apt_1',
          'title': 'AC Maintenance',
          'startsAt': '2026-09-01T06:00:00Z',
          'status': 'Confirmed',
          'statusTone': 'success',
        },
      ]);

      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      // 12-hour with AM/PM in both languages, per the localization rules —
      // never the device's 24-hour preference.
      expect(find.textContaining(RegExp('AM|PM')), findsOneWidget);
      expect(find.textContaining('Sep'), findsOneWidget);
    });
  });

  group('branch_card', () {
    testWidgets('formats a sub-kilometre distance in metres', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'branch_card',
          'id': 'b',
          'branchId': 'br_1',
          'name': 'Downtown',
          'addressText': 'Sheikh Zayed Road',
          'distanceMeters': 450,
        },
      ]);

      expect(find.text('Downtown'), findsOneWidget);
      // Labelled, as Figma writes it — the client owns both the word and the
      // unit, so the agent sends only the number of metres.
      expect(find.text('Distance: 450 m'), findsOneWidget);
    });

    testWidgets('switches to kilometres past 1000 m', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'branch_card',
          'id': 'b',
          'branchId': 'br_1',
          'name': 'Marina',
          'distanceMeters': 4800,
        },
      ]);

      expect(find.text('Distance: 4.8 km'), findsOneWidget);
    });
  });

  group('document_card', () {
    testWidgets('renders its status badge', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'document_card',
          'id': 'd',
          'documentId': 'doc_1',
          'title': 'Trade licence',
          'status': 'Expiring soon',
          'statusTone': 'warning',
        },
      ]);

      expect(find.text('Trade licence'), findsOneWidget);
      expect(find.text('Expiring soon'), findsOneWidget);
    });
  });

  group('order_card', () {
    testWidgets('renders the reference, the status and the amount', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'order_card',
          'id': 'o',
          'orderId': 'ord_1042',
          'title': 'Order #1042',
          'statusText': 'In progress',
          'status': 'Active',
          'statusTone': 'success',
          'amount': {'amount': 90, 'currency': 'AED'},
        },
      ]);

      expect(find.text('Order #1042'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      // The amount is formatted client-side from {amount, currency}.
      expect(find.textContaining('90'), findsOneWidget);
      expect(find.textContaining('AED'), findsOneWidget);
    });

    testWidgets('renders without a badge when the agent sends no status', (
      tester,
    ) async {
      // Figma badges only the active order; both rows still carry prose.
      await pumpNodes(tester, [
        {
          'type': 'order_card',
          'id': 'o',
          'orderId': 'ord_1042',
          'title': 'Order #1042',
          'statusText': 'Delivered',
        },
      ]);

      expect(find.byType(AiCardBadge), findsNothing);
      expect(find.text('Delivered'), findsOneWidget);
    });
  });

  group('provider_card', () {
    testWidgets('renders name, role, rating and stats', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'provider_card',
          'id': 'p',
          'providerId': 'prv_1',
          'name': 'Ahmed K.',
          'roleText': 'AC and plumbing specialist',
          'ratingValue': 4.8,
          'stats': [
            {'label': 'Completed jobs', 'value': '340+'},
            {'label': 'Since', 'value': '2021'},
          ],
        },
      ]);

      expect(find.text('Ahmed K.'), findsOneWidget);
      expect(find.text('AC and plumbing specialist'), findsOneWidget);
      expect(find.byType(AiRatingRow), findsOneWidget);
      expect(find.text('340+'), findsOneWidget);
      expect(find.text('2021'), findsOneWidget);
    });

    testWidgets('a call action reaches its handler with the number', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'provider_card',
          'id': 'p',
          'providerId': 'prv_1',
          'name': 'Ahmed K.',
          'actions': [
            {
              'label': 'Call',
              'variant': 'outline',
              'action': {'type': 'call_phone', 'phone': '+971501234567'},
            },
          ],
        },
      ]);

      await tapText(tester, 'Call');

      expect(
        harness.callsTo(AiUiActionType.callPhone).single.params['phone'],
        '+971501234567',
      );
    });
  });

  group('the attached action row', () {
    testWidgets('draws one button per entry, inside the card', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'appointment_card',
          'id': 'a',
          'appointmentId': 'apt_1',
          'title': 'AC Maintenance',
          'startsAt': '2026-09-01T06:00:00Z',
          'actions': [
            {
              'label': 'Reschedule',
              'variant': 'outline',
              'action': {'type': 'send_message', 'text': 'Reschedule'},
            },
            {
              'label': 'Cancel',
              'variant': 'outline',
              'intent': 'destructive',
              'action': {'type': 'send_message', 'text': 'Cancel'},
            },
          ],
        },
      ]);

      expect(find.byType(AiCardActionRow), findsOneWidget);
      expect(find.byType(AiCardButton), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byType(AiSemanticCard),
          matching: find.byType(AiCardActionRow),
        ),
        findsOneWidget,
        reason: 'Figma puts the buttons inside the card, not under it',
      );
    });

    testWidgets('dispatches the tapped entry only', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'branch_card',
          'id': 'b',
          'branchId': 'br_1',
          'name': 'Downtown',
          'actions': [
            {
              'label': 'Directions',
              'action': {'type': 'open_map', 'query': 'Downtown branch'},
            },
            {
              'label': 'Open',
              'action': {'type': 'open_branch', 'branchId': 'br_1'},
            },
          ],
        },
      ]);

      await tapText(tester, 'Directions');

      expect(harness.callsTo(AiUiActionType.openMap), hasLength(1));
      expect(harness.callsTo(AiUiActionType.openBranch), isEmpty);
    });

    testWidgets('a card with no actions draws no row', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'branch_card',
          'id': 'b',
          'branchId': 'br_1',
          'name': 'Downtown',
        },
      ]);

      expect(find.byType(AiCardButton), findsNothing);
    });
  });

  group('mixed message', () {
    testWidgets('text, semantic card and buttons render in one surface', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {'type': 'text', 'id': 't', 'text': 'Your appointment is confirmed'},
        {
          'type': 'appointment_card',
          'id': 'a',
          'appointmentId': 'apt_1',
          'title': 'AC Maintenance',
          'startsAt': '2026-09-01T06:00:00Z',
        },
        {
          'type': 'row',
          'id': 'r',
          'children': [
            {
              'type': 'button',
              'id': 'b1',
              'label': 'Reschedule',
              'variant': 'outline',
              'size': 'small',
              'action': {'type': 'open_appointment', 'appointmentId': 'apt_1'},
            },
            {
              'type': 'button',
              'id': 'b2',
              'label': 'Done',
              'size': 'small',
              'action': {'type': 'send_message', 'text': 'Thanks'},
            },
          ],
        },
      ]);

      expect(find.text('Your appointment is confirmed'), findsOneWidget);
      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.byType(AppButton), findsNWidgets(2));
    });
  });

  group('provider_card as an offer', () {
    Map<String, dynamic> offerCard({
      String presentation = 'compact',
      bool verified = true,
    }) => {
      'type': 'provider_card',
      'id': 'prv_card',
      'providerId': 'prv_ahmed',
      'name': 'Ahmed K',
      'roleText': 'AC & Plumbing Specialist',
      'verified': verified,
      'presentation': presentation,
      'distanceMeters': 2500,
      'description':
          'Premium eco-friendly yacht & vehicle cleaning specialist.',
      'services': ['Interior clean', 'Polishing'],
      'servicesLabel': 'Services',
      'photos': [
        {'url': 'https://cdn.trysanad.us/work/1.jpg'},
        {'url': 'https://cdn.trysanad.us/work/2.jpg'},
      ],
      'proposedTimeLabel': 'Proposed Time',
      'proposedTime': '2026-11-19T13:00:00Z',
      'offer': {
        'offerId': 'off_77',
        'acceptLabel': 'Accept Offer',
        'declineLabel': 'Decline',
        'acceptTemplate': "I'll take Ahmed's offer",
        'declineTemplate': 'Not this one',
      },
    };

    testWidgets('the compact reading shows identity, time and controls', (
      tester,
    ) async {
      await pumpNodes(tester, [offerCard()]);

      expect(find.text('Ahmed K'), findsOneWidget);
      expect(find.text('AC & Plumbing Specialist'), findsOneWidget);
      expect(find.text('Proposed Time'), findsOneWidget);
      expect(find.text('Accept Offer'), findsOneWidget);
      expect(find.text('Decline'), findsOneWidget);
    });

    testWidgets('the compact reading withholds the detail', (tester) async {
      await pumpNodes(tester, [offerCard()]);

      expect(find.text('Services'), findsNothing);
      expect(find.text('Interior clean'), findsNothing);
      expect(find.byType(AiPhotoStrip), findsNothing);
    });

    testWidgets('the expanded reading shows it', (tester) async {
      await pumpNodes(tester, [offerCard(presentation: 'expanded')]);

      expect(find.text('Services'), findsOneWidget);
      expect(find.text('Interior clean'), findsOneWidget);
      expect(find.text('Polishing'), findsOneWidget);
      expect(find.byType(AiPhotoStrip), findsOneWidget);
      expect(find.textContaining('eco-friendly'), findsOneWidget);
    });

    testWidgets('the disclosure control toggles between them', (tester) async {
      // Expansion is presentation, so it stays widget-local and reports
      // nothing — unlike the offer underneath it.
      await pumpNodes(tester, [offerCard()]);

      expect(find.byType(AiDisclosureButton), findsOneWidget);
      await tester.tap(find.byType(AiDisclosureButton));
      await tester.pump();

      expect(find.text('Services'), findsOneWidget);
    });

    testWidgets('a card with nothing more to show has no chevron', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'provider_card',
          'id': 'prv_plain',
          'providerId': 'prv_1',
          'name': 'Ahmed K',
        },
      ]);

      expect(find.byType(AiDisclosureButton), findsNothing);
    });

    testWidgets('the verification tick appears only when asserted', (
      tester,
    ) async {
      await pumpNodes(tester, [offerCard()]);
      expect(find.byIcon(Icons.verified_rounded), findsOneWidget);

      await pumpNodes(tester, [offerCard(verified: false)]);
      expect(find.byIcon(Icons.verified_rounded), findsNothing);
    });

    testWidgets('accepting submits a typed decision naming the provider', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [offerCard()],
        harness: RendererHarness(recordInteractions: true),
        messageId: 'msg_4',
      );

      await tapText(tester, 'Accept Offer');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.offerResolved);
      expect(result.nodeType, AiUiNodeType.providerCard);
      expect(result.messageId, 'msg_4');
      expect(
        result.value,
        const AiUiOfferValue(
          decision: AiUiOfferDecision.accepted,
          providerId: 'prv_ahmed',
          offerId: 'off_77',
        ),
      );
      expect(result.text, "I'll take Ahmed's offer");
    });

    testWidgets('declining is an answer, not a cancellation', (tester) async {
      final harness = await pumpNodes(
        tester,
        [offerCard()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Decline');

      final result = harness.submissions.single;
      expect(result.status, AiUiInteractionStatus.submitted);
      expect(
        (result.value as AiUiOfferValue).decision,
        AiUiOfferDecision.declined,
      );
    });

    testWidgets('an offer cannot be answered twice', (tester) async {
      final harness = await pumpNodes(
        tester,
        [offerCard()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Accept Offer');
      await tapText(tester, 'Decline');

      expect(harness.submissions, hasLength(1));
    });

    testWidgets("with no sink it posts the agent's sentence as before", (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [offerCard()]);

      await tapText(tester, 'Accept Offer');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        "I'll take Ahmed's offer",
      );
    });

    testWidgets('the proposed time is not squeezed by its own label', (
      tester,
    ) async {
      // Caught on device: a `Spacer` between the label and the value claimed
      // half the free space for itself, ellipsizing "19 Nov · 3:00 PM" into
      // "19 Nov · 3:0…". The value has to get the larger share of the row.
      await pumpNodes(tester, [offerCard()]);

      final label = tester.getRect(find.text('Proposed Time'));
      final value = tester.getRect(
        find.textContaining('19 Nov', findRichText: true),
      );

      expect(value.width, greaterThan(label.width));
    });

    testWidgets('it renders expanded in both directions', (tester) async {
      await pumpNodes(
        tester,
        [offerCard(presentation: 'expanded')],
        textDirection: TextDirection.rtl,
      );

      expect(find.text('Ahmed K'), findsOneWidget);
      expect(find.text('Interior clean'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a photo with no usable source falls back to the placeholder', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'provider_card',
          'id': 'prv_img',
          'providerId': 'prv_1',
          'name': 'Ahmed K',
          'presentation': 'expanded',
          'photos': [
            {'assetId': 'ai_map_preview'},
          ],
        },
      ]);

      expect(find.byType(AiPhotoStrip), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
