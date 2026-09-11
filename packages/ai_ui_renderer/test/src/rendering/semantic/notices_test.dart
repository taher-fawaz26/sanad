import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/renderer_test_support.dart';

/// The two cards that report something went differently than planned.
///
/// What matters for both is the pair of properties the reference design turns
/// on: the *content blocks are additive* — a notice draws whichever of its
/// status pill, context chip and draft tile the agent actually sent — and
/// every control produces a **typed** result that cannot be taken twice.
/// Anything less and "Create replacement request" could open two.
void main() {
  group('request_notice — the already-active-request reading', () {
    Map<String, dynamic> node() => {
      'type': 'request_notice',
      'id': 'rn_1',
      'title': 'New request detected',
      'body':
          'To keep your bids, schedules, and specialists organized correctly, '
          'each home service request needs its own separate conversation.',
      'requestId': 'req_4821',
      'contextLabel': 'Tied to Active Request: Plumbing Repair (#SND-4821)',
      'draftLabel': 'Draft Saved',
      'draftText': '"I also need to book an AC deep cleaning..."',
      'confirm': {
        'confirmLabel': 'Start New Conversation',
        'cancelLabel': 'Continue Plumbing Conversation',
        'confirmTemplate': 'Start a new conversation for the AC deep cleaning',
        'cancelTemplate': 'Carry on with the plumbing repair',
        'reference': 'req_4821',
      },
      'fallbackText': 'That needs its own conversation',
    };

    testWidgets('renders the chip, the explanation and the saved draft', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      expect(find.textContaining('Tied to Active Request'), findsOneWidget);
      expect(find.text('New request detected'), findsOneWidget);
      expect(
        find.textContaining('its own separate conversation'),
        findsOneWidget,
      );
      // Upper-cased by the renderer, which is presentation — the agent sent
      // "Draft Saved".
      expect(find.text('DRAFT SAVED'), findsOneWidget);
      expect(find.textContaining('AC deep cleaning'), findsOneWidget);
      expect(harness.diagnostics.diagnostics, isEmpty);
    });

    testWidgets('both controls render as full-width stacked pills', (
      tester,
    ) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Start New Conversation'), findsOneWidget);
      expect(find.text('Continue Plumbing Conversation'), findsOneWidget);
      // Stacked, not sharing a row: a half-width pill ellipsizes the second
      // label to nothing, which is the layout bug the reading exists to avoid.
      expect(find.byType(AiPromptButton), findsNWidgets(2));
    });

    testWidgets('starting a new conversation submits a typed yes', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
        messageId: 'msg_1',
      );

      await tapText(tester, 'Start New Conversation');

      final interaction = harness.submissions.single;
      expect(interaction.kind, AiUiInteractionKind.confirmationResolved);
      expect(interaction.nodeType, AiUiNodeType.requestNotice);
      expect(interaction.nodeId, 'rn_1');
      expect(interaction.messageId, 'msg_1');
      expect(interaction.status, AiUiInteractionStatus.submitted);

      final value = interaction.value as AiUiConfirmationValue;
      expect(value.confirmed, isTrue);
      expect(value.reference, 'req_4821');
      expect(
        interaction.text,
        'Start a new conversation for the AC deep cleaning',
      );
    });

    testWidgets('continuing the existing one is an answer, not a dismissal', (
      tester,
    ) async {
      // `submitted` with `confirmed: false`, never `cancelled`: the user
      // answered the question, and an agent that read the status alone would
      // re-ask something it has already been told.
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Continue Plumbing Conversation');

      final interaction = harness.submissions.single;
      expect(interaction.status, AiUiInteractionStatus.submitted);
      expect((interaction.value as AiUiConfirmationValue).confirmed, isFalse);
      expect(interaction.text, 'Carry on with the plumbing repair');
    });

    testWidgets('the decision cannot be taken twice', (tester) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Start New Conversation');
      await tapText(tester, 'Continue Plumbing Conversation');

      expect(harness.submissions, hasLength(1));
      expect(harness.stateOf('rn_1'), AiUiNodeInteractionState.submitted);
    });

    testWidgets('a failed send leaves the card answerable', (tester) async {
      final harness = RendererHarness(recordInteractions: true);
      await pumpNodes(tester, [node()], harness: harness);

      harness.interactions!.failNext = true;
      await tapText(tester, 'Start New Conversation');

      expect(harness.stateOf('rn_1'), AiUiNodeInteractionState.failed);

      await tapText(tester, 'Start New Conversation');
      expect(harness.submissions, hasLength(2));
    });
  });

  group('request_notice — the provider-cancelled reading', () {
    Map<String, dynamic> node() => {
      'type': 'request_notice',
      'id': 'rn_2',
      'status': {'label': 'Booking Cancelled', 'tone': 'error'},
      'reference': '#SND-4821',
      'requestId': 'req_4821',
      'title': 'Ahmed K. had to cancel',
      'body':
          'The provider canceled due to an unexpected emergency. '
          "We're sorry for the inconvenience.",
      'confirm': {
        'confirmLabel': 'Auto-Match New Provider',
        'confirmTemplate': 'Find me another provider',
        'reference': 'req_4821',
      },
      'actions': [
        {
          'label': 'Contact Sanad Support',
          'variant': 'outline',
          'action': {'type': 'send_message', 'text': 'Connect me to support'},
        },
      ],
    };

    testWidgets('renders the status pill beside its reference', (tester) async {
      await pumpNodes(tester, [node()]);

      expect(find.text('Booking Cancelled'), findsOneWidget);
      expect(find.text('Ahmed K. had to cancel'), findsOneWidget);
      expect(find.textContaining('unexpected emergency'), findsOneWidget);
      // Wrapped in bidi isolates, so the leading hash cannot reorder under
      // RTL — the SAN-770 value class.
      expect(find.text('#SND-4821'.ltrIsolated), findsOneWidget);
    });

    testWidgets('the decision and the extra destination are both offered', (
      tester,
    ) async {
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
      );

      await tapText(tester, 'Auto-Match New Provider');
      expect(
        harness.submissions.single.kind,
        AiUiInteractionKind.confirmationResolved,
      );

      // Support is a different destination, not a "no": it dispatches an
      // action and produces no answer at all.
      await tapText(tester, 'Contact Sanad Support');
      expect(harness.submissions, hasLength(1));
      expect(
        harness.callsTo(AiUiActionType.sendMessage).single.text,
        'Connect me to support',
      );
    });

    testWidgets('a notice with no status still renders its headline', (
      tester,
    ) async {
      // The provider-late reading, minus the pill the agent chose to omit.
      final harness = await pumpNodes(tester, [
        {
          'type': 'request_notice',
          'id': 'rn_3',
          'title': 'Scheduled arrival: 10:00 AM',
          'body': 'We checked the scheduled arrival time.',
          'confirm': {'confirmLabel': 'Create replacement request'},
        },
      ]);

      expect(find.text('Scheduled arrival: 10:00 AM'), findsOneWidget);
      expect(find.text('Create replacement request'), findsOneWidget);
      expect(harness.diagnostics.diagnostics, isEmpty);
    });

    testWidgets('a single-control notice draws one full-width pill', (
      tester,
    ) async {
      await pumpNodes(tester, [
        {
          'type': 'request_notice',
          'id': 'rn_4',
          'title': 'Scheduled arrival: 10:00 AM',
          'confirm': {'confirmLabel': 'Create replacement request'},
        },
      ]);

      expect(find.byType(AiPromptButton), findsOneWidget);
    });

    testWidgets('it renders in both directions without overflowing', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await pumpNodes(tester, [node()], textDirection: direction);

        expect(find.text('Ahmed K. had to cancel'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('service_area_notice', () {
    Map<String, dynamic> node({String? changeLabel = 'Change Location'}) => {
      'type': 'service_area_notice',
      'id': 'sa_1',
      'title': 'Location outside service area',
      'addressText': 'Al Ruwais, Western Region, Abu Dhabi',
      'body': 'This address is currently outside our service area:',
      if (changeLabel != null) 'changeLabel': changeLabel,
      'fallbackText': 'Al Ruwais is outside our service area',
    };

    testWidgets('renders the banner, the reason and the refused address', (
      tester,
    ) async {
      final harness = await pumpNodes(tester, [node()]);

      expect(find.text('Location outside service area'), findsOneWidget);
      expect(find.textContaining('outside our service area'), findsOneWidget);
      expect(
        find.text('Al Ruwais, Western Region, Abu Dhabi'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.wrong_location_outlined), findsOneWidget);
      expect(harness.diagnostics.diagnostics, isEmpty);
    });

    testWidgets("changing the location runs the app's own flow", (
      tester,
    ) async {
      // Not a new location model and not an agent-chosen destination: the same
      // `request_location_share` capability `location_confirm` already asks
      // for, carrying this node's id so the outcome comes back correlated.
      final harness = await pumpNodes(
        tester,
        [node()],
        harness: RendererHarness(recordInteractions: true),
        messageId: 'msg_9',
      );

      await tapText(tester, 'Change Location');

      final call = harness.callsTo(AiUiActionType.requestLocationShare).single;
      expect(call.params[AiUiInteractionParams.nodeId], 'sa_1');
      expect(call.params[AiUiInteractionParams.messageId], 'msg_9');
      // The outcome is the app's to report — nothing is answered here.
      expect(harness.submissions, isEmpty);
    });

    testWidgets('without a change label it is a statement', (tester) async {
      await pumpNodes(tester, [node(changeLabel: null)]);

      expect(find.text('Location outside service area'), findsOneWidget);
      expect(find.byType(AiPromptButton), findsNothing);
    });

    testWidgets('it renders in both directions without overflowing', (
      tester,
    ) async {
      for (final direction in TextDirection.values) {
        await pumpNodes(tester, [node()], textDirection: direction);

        expect(
          find.text('Al Ruwais, Western Region, Abu Dhabi'),
          findsOneWidget,
        );
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
}
