import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

/// The three cards that report where something has got to, and the one that
/// asks a destructive yes-or-no.
///
/// For the most part what is under test is that they *say the right thing* —
/// the loading vocabulary follows `progress`, the empty state replaces it once
/// a search is exhausted, the rail glyph follows the timeline state, the code
/// keeps its order. Where a card does take an answer — `provider_search`'s own
/// `confirm` block, and the destructive yes-or-no — what matters is that the
/// control produces a typed result and cannot be taken twice.
void main() {
  group('provider_search', () {
    Map<String, dynamic> node({double? progress}) => {
      'type': 'provider_search',
      'id': 'ps_1',
      'statusLabel': 'Finding providers...',
      'title': 'Searching nearby providers',
      'body':
          "We're matching your request with available providers in your area.",
      if (progress != null) 'progress': progress,
    };

    testWidgets('renders the pill, the headline and the explanation', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Finding providers...'), findsOneWidget);
      expect(find.text('Searching nearby providers'), findsOneWidget);
      expect(find.textContaining('matching your request'), findsOneWidget);
    });

    testWidgets('an indeterminate search draws the shared loading glyph', (
      tester,
    ) async {
      // Reusing the primitive rather than a bespoke dot animation is the whole
      // reason this node does not need one of its own.
      await pumpNodes(tester, [node()]);

      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.byType(AppProgressBar), findsNothing);
    });

    testWidgets('a determinate search draws the shared progress bar', (
      tester,
    ) async {
      await pumpNodes(tester, [node(progress: 0.4)]);

      expect(find.byType(AppProgressBar), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsNothing);
    });

    testWidgets('it survives with nothing but a title', (tester) async {
      final harness = await pumpNodes(tester, [
        {'type': 'provider_search', 'id': 'ps_2', 'title': 'Looking'},
      ]);

      expect(find.text('Looking'), findsOneWidget);
      expect(harness.diagnostics.diagnostics, isEmpty);
    });

    testWidgets('it renders in both directions', (tester) async {
      await pumpNodes(tester, [node()], textDirection: TextDirection.rtl);

      expect(find.text('Searching nearby providers'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a running search can be acknowledged', (tester) async {
      // "Continue in Background" is a decision about *this* search, so it
      // travels as a typed confirmation rather than as prose the agent would
      // have to re-read — and the ledger is what stops a second tap.
      final harness = await pumpNodes(
        tester,
        [
          {
            ...node(),
            'confirm': {
              'confirmLabel': 'Continue in Background',
              'confirmTemplate': 'Keep looking and let me know',
              'reference': 'req_4821',
            },
          },
        ],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Continue in Background');

      final interaction = harness.submissions.single;
      expect(interaction.kind, AiUiInteractionKind.confirmationResolved);
      expect(interaction.nodeType, AiUiNodeType.providerSearch);
      expect((interaction.value as AiUiConfirmationValue).confirmed, isTrue);
      expect(
        (interaction.value as AiUiConfirmationValue).reference,
        'req_4821',
      );
    });
  });

  group('provider_search — exhausted', () {
    Map<String, dynamic> node() => {
      'type': 'provider_search',
      'id': 'ps_ex',
      'state': 'exhausted',
      'title': 'No Specialists Available',
      'body':
          'No active providers could match your AC Cleaning request for '
          'tomorrow at 10 AM.',
      'confirm': {
        'confirmLabel': 'Change Time Slot',
        'cancelLabel': 'Cancel',
        'confirmTemplate': 'Let us try another time',
        'cancelTemplate': 'Cancel this request',
        'reference': 'req_4821',
      },
      'fallbackText': 'No specialists are available for that slot',
    };

    testWidgets('it draws the empty state instead of an indicator', (
      tester,
    ) async {
      // A spinner under "No Specialists Available" would say the opposite of
      // the headline: there is nothing in flight to indicate any more.
      await pumpNodes(tester, [node()]);

      expect(find.text('No Specialists Available'), findsOneWidget);
      expect(
        find.textContaining('could match your AC Cleaning'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.handyman_outlined), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsNothing);
      expect(find.byType(AppProgressBar), findsNothing);
    });

    testWidgets('changing the slot answers rather than mutating', (
      tester,
    ) async {
      // The card produces a result and the conversation continues from it —
      // nothing about the request is changed inside the widget.
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Change Time Slot');

      final interaction = harness.submissions.single;
      expect(interaction.kind, AiUiInteractionKind.confirmationResolved);
      expect(interaction.status, AiUiInteractionStatus.submitted);
      expect((interaction.value as AiUiConfirmationValue).confirmed, isTrue);
      expect(interaction.text, 'Let us try another time');
    });

    testWidgets('cancelling is a submitted no, not a cancelled interaction', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Cancel');

      final interaction = harness.submissions.single;
      expect(interaction.status, AiUiInteractionStatus.submitted);
      expect((interaction.value as AiUiConfirmationValue).confirmed, isFalse);
      expect(interaction.text, 'Cancel this request');
    });

    testWidgets('the pair cannot be answered twice', (tester) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Change Time Slot');
      await tapText(tester, 'Cancel');

      expect(harness.submissions, hasLength(1));
      expect(harness.stateOf('ps_ex'), AiUiNodeInteractionState.submitted);
    });

    testWidgets('it renders in both directions without overflowing', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await pumpNodes(tester, [node()], textDirection: direction);

        expect(find.text('No Specialists Available'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('it fits a 360dp device', (tester) async {
      tester.view.physicalSize = const Size(360 * 3, 800 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpNodes(tester, [node()]);

      expect(tester.takeException(), isNull);
    });
  });

  group('service_timeline', () {
    Map<String, dynamic> node() => {
      'type': 'service_timeline',
      'id': 'tl_1',
      'title': 'Timeline',
      'status': 'In Progress',
      'statusTone': 'success',
      'items': [
        {
          'state': 'completed',
          'title': 'Booking Confirmed',
          'description': 'Your booking has been confirmed',
          'at': '2026-11-17T09:45:00Z',
        },
        {
          'state': 'active',
          'title': 'En Route',
          'description': 'Provider is on the way',
          'at': '2026-11-17T10:45:00Z',
        },
        {
          'state': 'pending',
          'title': 'Service Completed',
          'description': 'Awaiting service completion',
        },
      ],
      'actions': [
        {
          'label': 'Mark as Complete',
          'action': {'type': 'send_message', 'text': 'It is done'},
        },
      ],
    };

    testWidgets("renders every step in the agent's own order", (tester) async {
      await pumpNodes(tester, [node()]);

      final titles = tester
          .widgetList<Text>(find.byType(Text))
          .map((text) => text.data)
          .whereType<String>()
          .toList();

      expect(
        titles.indexOf('Booking Confirmed') < titles.indexOf('En Route'),
        isTrue,
      );
      expect(
        titles.indexOf('En Route') < titles.indexOf('Service Completed'),
        isTrue,
      );
    });

    testWidgets('the rail glyph follows the state, never the prose', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_checked_rounded), findsOneWidget);
      expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    });

    testWidgets('a cancelled step never shows a tick', (tester) async {
      await pumpNodes(tester, [
        {
          'type': 'service_timeline',
          'id': 'tl_2',
          'items': [
            {'state': 'cancelled', 'title': 'Service Cancelled'},
          ],
        },
      ]);

      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);
    });

    testWidgets('a step with no timestamp lays out without one', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(tester.takeException(), isNull);
      expect(find.text('Service Completed'), findsOneWidget);
    });

    testWidgets('its action dispatches', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Mark as Complete');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'It is done',
      );
    });

    testWidgets('it renders in both directions without overflowing', (
      tester,
    ) async {
      await pumpNodes(tester, [node()], textDirection: TextDirection.rtl);

      expect(find.text('En Route'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('verification_code', () {
    Map<String, dynamic> node({String code = '65066'}) => {
      'type': 'verification_code',
      'id': 'vc_1',
      'label': 'verification code',
      'body':
          'Share this code with the service provider after completing the '
          'service for confirmation',
      'code': code,
      'actions': [
        {
          'label': 'Copy',
          'variant': 'outline',
          'action': {'type': 'copy_text', 'text': code},
        },
      ],
    };

    testWidgets('draws one box per character', (tester) async {
      await pumpNodes(tester, [node()]);

      for (final digit in ['6', '5', '0', '6', '6']) {
        expect(find.text(digit), findsWidgets, reason: digit);
      }
      expect(find.byType(AiCodeRow), findsOneWidget);
    });

    testWidgets('the row stays left-to-right under RTL', (tester) async {
      // A code is an ordered sequence: mirroring the row would read it back to
      // front, which is the one case `ui.md` allows forcing a direction for.
      await pumpNodes(tester, [node()], textDirection: TextDirection.rtl);

      final directionality = tester.widget<Directionality>(
        find
            .descendant(
              of: find.byType(AiCodeRow),
              matching: find.byType(Directionality),
            )
            .first,
      );

      expect(directionality.textDirection, TextDirection.ltr);
    });

    testWidgets('it offers no way to type a code', (tester) async {
      // Display-only by design: a code field an agent can put in front of
      // someone is what a phishing payload looks like.
      await pumpNodes(tester, [node()]);

      expect(find.byType(TextField), findsNothing);
      expect(find.byType(EditableText), findsNothing);
    });

    testWidgets('its copy action dispatches with the code', (tester) async {
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Copy');

      expect(harness.callsTo(AiUiActionType.copyText).single.text, '65066');
    });

    testWidgets('it survives with nothing but a code', (tester) async {
      final harness = await pumpNodes(tester, [
        {'type': 'verification_code', 'id': 'vc_2', 'code': '4821'},
      ]);

      expect(find.text('4'), findsOneWidget);
      expect(harness.diagnostics.diagnostics, isEmpty);
    });
  });

  group('confirm_prompt', () {
    Map<String, dynamic> node({bool destructive = true}) => {
      'type': 'confirm_prompt',
      'id': 'cp_1',
      'title': 'Are you sure you want to cancel?',
      'subjectTitle': 'AC Maintenance',
      'subjectSubtitle': 'Lina M • Tomorrow 10:00 AM',
      'tone': 'error',
      'confirm': {
        'confirmLabel': 'Yes, Cancel',
        'cancelLabel': 'Keep It',
        'confirmTemplate': 'Yes, cancel my AC Maintenance booking',
        'cancelTemplate': 'Keep it',
        'reference': 'req_1042',
        'destructive': destructive,
      },
    };

    testWidgets('renders the question and what is being decided about', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Are you sure you want to cancel?'), findsOneWidget);
      expect(find.text('AC Maintenance'), findsOneWidget);
      expect(find.text('Lina M • Tomorrow 10:00 AM'), findsOneWidget);
      expect(find.byType(AiSubjectTile), findsOneWidget);
    });

    testWidgets('confirming submits a typed yes carrying the reference', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
        messageId: 'msg_9',
      );

      await tapText(tester, 'Yes, Cancel');

      final result = harness.submissions.single;
      expect(result.kind, AiUiInteractionKind.confirmationResolved);
      expect(result.nodeType, AiUiNodeType.confirmPrompt);
      expect(result.messageId, 'msg_9');
      expect(
        result.value,
        const AiUiConfirmationValue(confirmed: true, reference: 'req_1042'),
      );
      expect(result.text, 'Yes, cancel my AC Maintenance booking');
    });

    testWidgets('declining is an answer, not a cancellation', (tester) async {
      // The distinction the agent acts on: "no" is a decision it must respect,
      // where a cancelled interaction means the user never answered.
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Keep It');

      final result = harness.submissions.single;
      expect(result.status, AiUiInteractionStatus.submitted);
      expect(
        result.value,
        const AiUiConfirmationValue(confirmed: false, reference: 'req_1042'),
      );
    });

    testWidgets('a second tap cannot answer twice', (tester) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Yes, Cancel');
      await tapText(tester, 'Keep It');

      expect(harness.submissions, hasLength(1));
      expect(harness.stateOf('cp_1'), AiUiNodeInteractionState.submitted);
    });

    testWidgets('with no sink it falls back to posting the sentence', (
      tester,
    ) async {
      // The compatibility guarantee every other interactive card keeps.
      final harness = await pumpNodes(tester, [node()]);

      await tapText(tester, 'Yes, Cancel');

      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Yes, cancel my AC Maintenance booking',
      );
    });

    testWidgets('it renders in both directions', (tester) async {
      await pumpNodes(tester, [node()], textDirection: TextDirection.rtl);

      expect(find.text('Yes, Cancel'), findsOneWidget);
      expect(find.text('Keep It'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a prompt with no cancel label still answers', (tester) async {
      final harness = await pumpNodes(
        tester,
        [
          {
            'type': 'confirm_prompt',
            'id': 'cp_2',
            'title': 'Submit this request?',
            'confirm': {'confirmLabel': 'Submit'},
          },
        ],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Submit');

      expect(
        harness.submissions.single.value,
        const AiUiConfirmationValue(confirmed: true),
      );
    });
  });
}
