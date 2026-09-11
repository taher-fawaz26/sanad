import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

/// The three cards that read a set of values back — `booking_summary`,
/// `request_summary`, `payment_receipt`.
///
/// Every payload here goes through the real validator and the real
/// `AiUiSurface`, so a renderer can never be tested against a node shape the
/// validator would not actually produce.
void main() {
  group('booking_summary', () {
    testWidgets('renders the header and every label-value pair', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'booking_summary',
          'id': 'b',
          'title': 'Booking Summary',
          'items': [
            {'label': 'Service', 'value': 'Deep Cleaning'},
            {'label': 'Provider', 'value': 'CleanCo Marina'},
            {
              'label': 'Estimated Cost',
              'value': '150 AED',
              'valueTone': 'primary',
            },
          ],
        },
      ]);

      expect(find.text('Booking Summary'), findsOneWidget);
      expect(find.text('Service'), findsOneWidget);
      expect(find.text('Deep Cleaning'), findsOneWidget);
      expect(find.text('CleanCo Marina'), findsOneWidget);
      expect(find.byType(AiDetailRow), findsNWidgets(3));
    });

    testWidgets('tints the emphasised value and leaves the others alone', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'booking_summary',
          'id': 'b',
          'items': [
            {'label': 'Service', 'value': 'Deep Cleaning'},
            {'label': 'Cost', 'value': '150 AED', 'valueTone': 'primary'},
          ],
        },
      ]);

      final plain = tester.widget<Text>(find.text('Deep Cleaning'));
      final tinted = tester.widget<Text>(find.text('150 AED'));
      expect(
        tinted.style!.color,
        isNot(plain.style!.color),
        reason: 'Figma emphasises the cost row',
      );
    });

    testWidgets('renders its actions inside the card', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'booking_summary',
          'id': 'b',
          'title': 'Booking Summary',
          'items': [
            {'label': 'Service', 'value': 'Deep Cleaning'},
          ],
          'actions': [
            {
              'label': 'Go back',
              'variant': 'secondary',
              'intent': 'neutral',
              'action': {'type': 'send_message', 'text': 'Go back'},
            },
            {
              'label': 'Confirm',
              'action': {'type': 'send_message', 'text': 'Confirm'},
            },
          ],
        },
      ]);

      expect(find.byType(AiCardButton), findsNWidgets(2));

      await tapText(tester, 'Confirm');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Confirm',
      );
    });

    testWidgets('survives a title long enough to need truncating', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'booking_summary',
          'id': 'b',
          'title': 'A booking summary title far longer than this card is wide',
          'items': [
            {'label': 'Service', 'value': 'Deep Cleaning'},
          ],
        },
      ]);

      expect(tester.takeException(), isNull);
    });
  });

  group('request_summary', () {
    Map<String, dynamic> node({Map<String, dynamic>? location}) => {
      'type': 'request_summary',
      'id': 'r',
      'items': [
        {'label': 'Service', 'value': 'Home Cleaning'},
        {'label': 'Location', 'value': 'Home - Dubai Marina'},
      ],
      'summaryTitle': 'Summary',
      'summaryText': 'A full home clean, eco-friendly products.',
      if (location != null) 'location': location,
    };

    testWidgets('renders bordered value tiles, the recap and the maps row', (
      tester,
    ) async {
      await pumpNodes(tester, [
        node(
          location: {
            'label': 'Home',
            'addressText': 'Dubai Marina, Tower 5',
            'action': {'type': 'open_map', 'query': 'Dubai Marina, Tower 5'},
          },
        ),
      ]);

      // Figma nests each value in its own white tile, not a plain row list.
      expect(find.byType(AiDetailTile), findsNWidgets(2));
      expect(find.text('Summary'), findsOneWidget);
      expect(
        find.text('A full home clean, eco-friendly products.'),
        findsOneWidget,
      );
      expect(find.byType(AiMapsLinkRow), findsOneWidget);
    });

    testWidgets('the maps row reaches its handler with the query', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [
        node(
          location: {
            'addressText': 'Dubai Marina',
            'action': {'type': 'open_map', 'query': 'Dubai Marina'},
          },
        ),
      ]);

      await tester.tap(find.byType(AiMapsLinkRow));
      await tester.pump();

      expect(
        harness.callsTo(AiUiActionType.openMap).single.params['query'],
        'Dubai Marina',
      );
    });

    testWidgets('an address with no action renders as static text', (
      tester,
    ) async {
      // The address is still information even when the maps link is not
      // available, so the row stays and only the link line goes.
      await pumpNodes(tester, [
        node(location: {'addressText': 'Dubai Marina'}),
      ]);

      expect(find.text('Dubai Marina'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AiMapsLinkRow),
          matching: find.byType(InkWell),
        ),
        findsNothing,
      );
    });

    testWidgets('renders without a location row at all', (tester) async {
      await pumpNodes(tester, [node()]);

      expect(find.byType(AiMapsLinkRow), findsNothing);
      expect(find.text('Home Cleaning'), findsOneWidget);
    });
  });

  group('payment_receipt', () {
    testWidgets('renders the headline, the rows and the total', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'payment_receipt',
          'id': 'p',
          'title': 'Payment Successful',
          'subtitle': 'Thank you for your order',
          'items': [
            {
              'label': 'Transaction ID',
              'value': 'TXN-8829410',
              'isLtrValue': true,
            },
            {'label': 'Payment Method', 'value': 'Apple Pay'},
          ],
          'total': {
            'label': 'Amount Paid',
            'amount': {'amount': 150, 'currency': 'AED'},
          },
        },
      ]);

      expect(find.text('Payment Successful'), findsOneWidget);
      expect(find.text('Thank you for your order'), findsOneWidget);
      expect(find.text('Apple Pay'), findsOneWidget);
      expect(find.text('Amount Paid'), findsOneWidget);
      // The total is formatted client-side from {amount, currency}.
      expect(find.textContaining('150'), findsOneWidget);
      expect(find.byType(AiToneDisc), findsOneWidget);
    });

    testWidgets('isolates a reference id so RTL cannot reorder it', (
      tester,
    ) async {
      // The SAN-770 class of bug: a leading symbol jumping to the far end.
      await pumpNodes(
        tester,
        [
          {
            'type': 'payment_receipt',
            'id': 'p',
            'title': 'Payment Successful',
            'items': [
              {
                'label': 'Transaction ID',
                'value': 'TXN-8829410',
                'isLtrValue': true,
              },
            ],
          },
        ],
        textDirection: TextDirection.rtl,
      );

      expect(find.text('TXN-8829410'), findsNothing);
      expect(find.text('TXN-8829410'.ltrIsolated), findsOneWidget);
    });

    testWidgets('a failed payment does not show a tick', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'payment_receipt',
          'id': 'p',
          'title': 'Payment failed',
          'statusTone': 'error',
          'items': <Object>[],
        },
      ]);

      expect(find.byIcon(Icons.check_rounded), findsNothing);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });

    testWidgets('renders with a total and no rows', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'payment_receipt',
          'id': 'p',
          'title': 'Payment Successful',
          'items': <Object>[],
          'total': {
            'label': 'Amount Paid',
            'amount': {'amount': 150, 'currency': 'AED'},
          },
        },
      ]);

      expect(tester.takeException(), isNull);
      // The total is its own emphasised row, not one of the detail rows.
      expect(find.byType(AiDetailRow), findsNothing);
      expect(find.text('Amount Paid'), findsOneWidget);
      expect(find.textContaining('150'), findsOneWidget);
    });

    testWidgets('a View receipt action reaches its handler', (tester) async {
      final harness = await pumpNodes(tester, [
        {
          'type': 'payment_receipt',
          'id': 'p',
          'title': 'Payment Successful',
          'items': <Object>[],
          'actions': [
            {
              'label': 'View Receipt',
              'variant': 'outline',
              'action': {'type': 'open_document', 'documentId': 'doc_1'},
            },
          ],
        },
      ]);

      await tapText(tester, 'View Receipt');

      expect(
        harness
            .callsTo(AiUiActionType.openDocument)
            .single
            .params['documentId'],
        'doc_1',
      );
    });
  });

  group('layout under pressure', () {
    testWidgets('every summary mirrors under RTL without overflowing', (
      tester,
    ) async {
      await pumpNodes(
        tester,
        [
          {
            'type': 'booking_summary',
            'id': 'b',
            'title': 'ملخص الحجز',
            'items': [
              {'label': 'الخدمة', 'value': 'تنظيف عميق'},
            ],
          },
          {
            'type': 'request_summary',
            'id': 'r',
            'items': [
              {'label': 'الخدمة', 'value': 'تنظيف المنزل'},
            ],
            'location': {'addressText': 'دبي مارينا'},
          },
          {
            'type': 'payment_receipt',
            'id': 'p',
            'title': 'تم الدفع بنجاح',
            'items': [
              {'label': 'طريقة الدفع', 'value': 'Apple Pay'},
            ],
          },
        ],
        textDirection: TextDirection.rtl,
      );

      expect(tester.takeException(), isNull);
    });

    testWidgets('long labels and values truncate rather than overflow', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'booking_summary',
          'id': 'b',
          'items': [
            {
              'label': 'An unusually long label for a summary row',
              'value': 'An unusually long value beside an unusually long label',
            },
          ],
        },
      ]);

      expect(tester.takeException(), isNull);
    });
  });

  group('booking_summary as a confirmation', () {
    Map<String, dynamic> confirmed({String tone = 'success'}) => {
      'type': 'booking_summary',
      'id': 'bs_1',
      'statusText': 'Booking Confirmed!',
      'statusTone': tone,
      'provider': {
        'providerId': 'prv_ahmed',
        'name': 'Ahmed K',
        'roleText': 'AC & Plumbing Specialist',
        'verified': true,
      },
      'items': [
        {'label': 'Date', 'value': 'Thursday, Oct 24'},
        {'label': 'Time', 'value': '5:00 PM'},
        {'label': 'Location', 'value': '91 Orchard St, New York'},
        {
          'label': 'Booking Reference',
          'value': '#SND-8829-AQ',
          'isLtrValue': true,
        },
      ],
    };

    testWidgets('renders the outcome, the provider and every fact', (
      tester,
    ) async {
      await pumpNodes(tester, [confirmed()]);

      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('Ahmed K'), findsOneWidget);
      expect(find.text('AC & Plumbing Specialist'), findsOneWidget);
      expect(find.text('Thursday, Oct 24'), findsOneWidget);
      expect(find.text('91 Orchard St, New York'), findsOneWidget);
    });

    testWidgets('a status turns the rows into the stacked reading', (
      tester,
    ) async {
      // The layout follows the data: a booking that has happened is a set of
      // facts, not a table of values to compare.
      await pumpNodes(tester, [confirmed()]);

      expect(find.byType(AiStackedDetails), findsOneWidget);
      expect(find.byType(AiDetailRows), findsNothing);
    });

    testWidgets('without a status it stays the summary it always was', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'booking_summary',
          'id': 'bs_2',
          'title': 'Booking summary',
          'items': [
            {'label': 'Service', 'value': 'Deep Cleaning'},
          ],
        },
      ]);

      expect(find.byType(AiDetailRows), findsOneWidget);
      expect(find.byType(AiStackedDetails), findsNothing);
    });

    testWidgets('the status glyph follows the tone', (tester) async {
      await pumpNodes(tester, [confirmed()]);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);

      await pumpNodes(tester, [confirmed(tone: 'error')]);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('a provider with no portrait shows the person glyph', (
      tester,
    ) async {
      await pumpNodes(tester, [confirmed()]);

      expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    });

    testWidgets('the reference keeps its leading hash under RTL', (
      tester,
    ) async {
      // `isLtrValue` wraps the value in bidi isolates — the SAN-770 bug class.
      await pumpNodes(
        tester,
        [confirmed()],
        textDirection: TextDirection.rtl,
      );

      expect(find.textContaining('SND-8829-AQ'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('request_summary photos and confirm', () {
    Map<String, dynamic> summary({bool withConfirm = true}) => {
      'type': 'request_summary',
      'id': 'rs_1',
      'items': [
        {'label': 'Service', 'value': 'Home Cleaning'},
        {'label': 'Location', 'value': 'Home - Dubai Marina'},
      ],
      'summaryTitle': 'Summery',
      'summaryText': 'The customer requested a full home cleaning service.',
      'photosLabel': 'photos',
      'photos': [
        {'url': 'https://cdn.trysanad.us/requests/1.jpg'},
        {'url': 'https://cdn.trysanad.us/requests/2.jpg'},
        {'url': 'https://cdn.trysanad.us/requests/3.jpg'},
      ],
      'location': {
        'addressText': 'Home - Dubai Marina',
        'action': {'type': 'open_map', 'query': 'Dubai Marina'},
      },
      if (withConfirm)
        'confirm': {
          'confirmLabel': 'Confirm',
          'cancelLabel': 'Cancel',
          'confirmTemplate': 'Yes, submit my request',
          'cancelTemplate': 'Not yet',
          'reference': 'req_1042',
        },
    };

    testWidgets('renders the photo strip under its label', (tester) async {
      await pumpNodes(tester, [summary()]);

      expect(find.text('photos'), findsOneWidget);
      expect(find.byType(AiPhotoStrip), findsOneWidget);
    });

    testWidgets('confirming submits a typed yes rather than only prose', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [summary()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Confirm');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.confirmationResolved);
      expect(result.nodeType, AiUiNodeType.requestSummary);
      expect(
        result.value,
        const AiUiConfirmationValue(confirmed: true, reference: 'req_1042'),
      );
    });

    testWidgets('cancelling submits the negative answer', (tester) async {
      final harness = await pumpNodes(
        tester,
        [summary()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Cancel');

      expect(
        harness.submissions.single.value,
        const AiUiConfirmationValue(confirmed: false, reference: 'req_1042'),
      );
    });

    testWidgets('the card cannot be submitted twice', (tester) async {
      final harness = await pumpNodes(
        tester,
        [summary()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Confirm');
      await tapText(tester, 'Confirm');

      expect(harness.submissions, hasLength(1));
    });

    testWidgets('a summary with no confirm block renders without controls', (
      tester,
    ) async {
      await pumpNodes(tester, [summary(withConfirm: false)]);

      expect(find.text('Confirm'), findsNothing);
      expect(find.text('Home Cleaning'), findsOneWidget);
    });

    testWidgets('it renders in both directions without overflowing', (
      tester,
    ) async {
      await pumpNodes(
        tester,
        [summary()],
        textDirection: TextDirection.rtl,
      );

      expect(find.text('Home Cleaning'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
