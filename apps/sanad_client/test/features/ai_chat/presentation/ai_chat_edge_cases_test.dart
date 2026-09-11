import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/edge_case_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/scenarios/scenario_support.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_message.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/active_stream_controller.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_chat_bubble.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/ai_transport_banner.dart';
import 'package:testing/testing.dart';

/// The chat edge cases, as the chat actually draws them.
///
/// Two halves, matching the two kinds of state in the reference set:
///
/// * the **payload** cases go through the real `AiChatConfig.validator` — the
///   app's own instance, with the app's own action and asset allowlists — into
///   the real bubble. A fixture that stopped validating renders nothing here
///   rather than silently keeping a widget alive that no live payload could
///   reach;
/// * the **lifecycle** cases (queued offline, failed to send) are asserted on
///   the bubble and the banner, because no payload can express them.
///
/// `.tr()` returns its key in a widget test — easy_localization is not
/// initialised — so the assertions name keys rather than English copy. That is
/// also the stronger assertion: it proves the string is localized at all.
void main() {
  final validator = AiChatConfig.validator(keepUnsupportedNodes: false);

  /// Pulls a scenario's `ui` payload and runs it through the real validator,
  /// exactly as the bloc does when the frame lands.
  AiUiParseResult parseScenario(MockScenario scenario) {
    final ui = scenario.build('msg_edge').whereType<AiChatUiEvent>().last;
    return validator.validate(ui.payload);
  }

  AiChatMessage assistantFor(MockScenario scenario) => AiChatMessage(
    id: 'msg_edge',
    role: AiChatRole.assistant,
    document: parseScenario(scenario).document,
  );

  late List<String> sentMessages;
  late List<AiUiAction> dispatched;
  late AiUiInteractionLedger ledger;
  late List<AiUiInteraction> submissions;
  late AiUiEnvironment environment;

  setUp(() {
    sentMessages = [];
    dispatched = [];
    submissions = [];
    ledger = AiUiInteractionLedger();
    addTearDown(ledger.dispose);

    environment = AiUiEnvironment(
      registry: defaultRendererRegistry(),
      ledger: ledger,
      interactions: _RecordingSink(submissions, ledger),
      actions: AiActionRegistry([
        SendMessageHandler(sentMessages.add),
        for (final type in const [
          AiUiActionType.requestLocationShare,
          AiUiActionType.openService,
        ])
          _RecordingHandler(type, dispatched),
      ]),
    );
  });

  Future<void> pumpBubble(
    WidgetTester tester,
    AiChatMessage message, {
    TextDirection textDirection = TextDirection.ltr,
    VoidCallback? onRetry,
  }) async {
    final controller = ActiveStreamController();
    addTearDown(controller.dispose);

    await pumpDsWidget(
      tester,
      AiUiHost(
        environment: environment,
        child: Directionality(
          textDirection: textDirection,
          child: Material(
            child: SingleChildScrollView(
              child: AiChatBubble(
                message: message,
                activeStream: controller,
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('every payload edge case validates and renders', () {
    // The set minus the send-failure scenario, which carries no `ui` frame at
    // all — it is a lifecycle case and is covered below.
    final payloadScenarios = edgeCaseScenarios
        .where((s) => s.id != messageSendFailedScenario.id)
        .toList();

    for (final scenario in payloadScenarios) {
      testWidgets('${scenario.id} validates with no diagnostics', (
        tester,
      ) async {
        final result = parseScenario(scenario);

        expect(result.document, isNotNull);
        expect(result.document!.blocks, isNotEmpty);
        expect(
          result.diagnostics,
          isEmpty,
          reason: '${scenario.id} produced ${result.diagnostics}',
        );
      });

      for (final direction in TextDirection.values) {
        testWidgets('${scenario.id} renders in $direction', (tester) async {
          await pumpBubble(
            tester,
            assistantFor(scenario),
            textDirection: direction,
          );

          expect(find.byType(AiChatBubble), findsOneWidget);
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('${scenario.id} fits a 360dp device', (tester) async {
        tester.view.physicalSize = const Size(360 * 3, 800 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpBubble(tester, assistantFor(scenario));

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('active request detected', () {
    testWidgets('draws the chip, the draft and both ways forward', (
      tester,
    ) async {
      await pumpBubble(tester, assistantFor(activeRequestDetectedScenario));

      expect(find.textContaining('Tied to Active Request'), findsOneWidget);
      expect(find.text('New request detected'), findsOneWidget);
      expect(find.text('DRAFT SAVED'), findsOneWidget);
      expect(find.textContaining('AC deep cleaning'), findsOneWidget);
      expect(find.text('Start New Conversation'), findsOneWidget);
      expect(find.text('Continue Plumbing Conversation'), findsOneWidget);
    });

    testWidgets('the choice reaches the interaction sink, not a text send', (
      tester,
    ) async {
      await pumpBubble(tester, assistantFor(activeRequestDetectedScenario));

      await tester.ensureVisible(find.text('Start New Conversation'));
      await tester.pump();
      await tester.tap(find.text('Start New Conversation'));
      await tester.pump();

      expect(submissions, hasLength(1));
      expect(
        submissions.single.kind,
        AiUiInteractionKind.confirmationResolved,
      );
      expect(submissions.single.nodeType, AiUiNodeType.requestNotice);
      expect(
        (submissions.single.value as AiUiConfirmationValue).reference,
        'req_4821',
      );
      // No hidden JSON smuggled through a plain message.
      expect(sentMessages, isEmpty);
    });
  });

  group('booking cancelled', () {
    testWidgets('the support control is an action, not an answer', (
      tester,
    ) async {
      await pumpBubble(tester, assistantFor(bookingCancelledScenario));

      await tester.ensureVisible(find.text('Contact Sanad Support'));
      await tester.pump();
      await tester.tap(find.text('Contact Sanad Support'));
      await tester.pump();

      expect(sentMessages, hasLength(1));
      expect(submissions, isEmpty);
    });
  });

  group('provider late', () {
    testWidgets('a replacement cannot be requested twice', (tester) async {
      // The one case where a double tap would be a real mutation: the ledger
      // is what makes a second tap inert.
      await pumpBubble(tester, assistantFor(providerLateScenario));

      final button = find.text('Create replacement request');
      await tester.ensureVisible(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();
      await tester.tap(button);
      await tester.pump();

      expect(submissions, hasLength(1));
      expect(ledger.stateOf('rn_late'), AiUiNodeInteractionState.submitted);
    });
  });

  group('searching and its empty result', () {
    testWidgets('a running search shows the indeterminate glyph', (
      tester,
    ) async {
      await pumpBubble(tester, assistantFor(providerSearchingScenario));

      expect(find.text('Finding providers...'), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsOneWidget);
      expect(find.text('Continue in Background'), findsOneWidget);
    });

    testWidgets('an exhausted search shows no indicator at all', (
      tester,
    ) async {
      await pumpBubble(tester, assistantFor(noSpecialistsAvailableScenario));

      expect(find.text('No Specialists Available'), findsOneWidget);
      expect(find.byType(AppLoadingIndicator), findsNothing);
      expect(find.text('Change Time Slot'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancelling answers rather than abandoning', (tester) async {
      await pumpBubble(tester, assistantFor(noSpecialistsAvailableScenario));

      await tester.ensureVisible(find.text('Cancel'));
      await tester.pump();
      await tester.tap(find.text('Cancel'));
      await tester.pump();

      final interaction = submissions.single;
      expect(interaction.status, AiUiInteractionStatus.submitted);
      expect(
        (interaction.value as AiUiConfirmationValue).confirmed,
        isFalse,
      );
    });
  });

  group('location outside service area', () {
    testWidgets("names the address and offers the app's own flow", (
      tester,
    ) async {
      await pumpBubble(
        tester,
        assistantFor(locationOutsideServiceAreaScenario),
      );

      expect(find.text('Location outside service area'), findsOneWidget);
      expect(
        find.text('Al Ruwais, Western Region, Abu Dhabi'),
        findsOneWidget,
      );

      await tester.ensureVisible(find.text('Change Location'));
      await tester.pump();
      await tester.tap(find.text('Change Location'));
      await tester.pump();

      expect(dispatched, hasLength(1));
      expect(dispatched.single.type, AiUiActionType.requestLocationShare);
    });
  });

  group('the message lifecycle states', () {
    AiChatMessage user(AiChatMessageStatus status) => AiChatMessage.user(
      id: 'user_1',
      text: 'I need AC repairing today',
      status: status,
    );

    Color fillOf(WidgetTester tester) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(AiChatBubble),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('a queued turn says it is waiting, not that it failed', (
      tester,
    ) async {
      await pumpBubble(tester, user(AiChatMessageStatus.queued));

      expect(find.text('ai_chat.message_pending_offline'), findsOneWidget);
      expect(find.text('ai_chat.message_not_sent'), findsNothing);
      expect(find.text('ai_chat.message_retry'), findsNothing);
    });

    testWidgets('a failed turn says so and offers Retry', (tester) async {
      var retried = 0;
      await pumpBubble(
        tester,
        user(AiChatMessageStatus.failed),
        onRetry: () => retried++,
      );

      expect(find.text('ai_chat.message_not_sent'), findsOneWidget);
      expect(find.text('ai_chat.message_pending_offline'), findsNothing);

      await tester.tap(find.text('ai_chat.message_retry'));
      await tester.pump();

      expect(retried, 1);
    });

    testWidgets('the three states are visually distinct', (tester) async {
      // The property the reference design turns on: a held turn, a failed one
      // and a delivered one must not look alike at a glance.
      await pumpBubble(tester, user(AiChatMessageStatus.queued));
      final queued = fillOf(tester);

      await pumpBubble(tester, user(AiChatMessageStatus.failed));
      final failed = fillOf(tester);

      await pumpBubble(tester, user(AiChatMessageStatus.complete));
      final delivered = fillOf(tester);

      expect(queued, isNot(failed));
      expect(queued, isNot(delivered));
      expect(failed, isNot(delivered));
    });

    testWidgets('a queued turn mirrors under RTL', (tester) async {
      await pumpBubble(
        tester,
        user(AiChatMessageStatus.queued),
        textDirection: TextDirection.rtl,
      );

      expect(find.text('ai_chat.message_pending_offline'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('the transport banner', () {
    Future<void> pumpBanner(
      WidgetTester tester, {
      required bool offline,
      required bool undelivered,
    }) => pumpDsWidget(
      tester,
      Material(
        child: AiTransportBanner(
          isOffline: offline,
          hasUndeliveredMessage: undelivered,
        ),
      ),
    );

    testWidgets('says nothing when the wire is healthy', (tester) async {
      await pumpBanner(tester, offline: false, undelivered: false);

      expect(find.byType(AppAlert), findsNothing);
    });

    testWidgets('offline reads as a warning, not an error', (tester) async {
      await pumpBanner(tester, offline: true, undelivered: false);

      expect(find.text('ai_chat.offline_banner'), findsOneWidget);
      expect(
        tester.widget<AppAlert>(find.byType(AppAlert)).type,
        AppAlertType.warning,
      );
    });

    testWidgets('a failed send reads as an error', (tester) async {
      await pumpBanner(tester, offline: false, undelivered: true);

      expect(find.text('ai_chat.send_failed_banner'), findsOneWidget);
      expect(
        tester.widget<AppAlert>(find.byType(AppAlert)).type,
        AppAlertType.error,
      );
    });

    testWidgets('offline wins when both hold', (tester) async {
      // Telling the user to check a network the banner above already says is
      // absent would ask them to fix something they can see.
      await pumpBanner(tester, offline: true, undelivered: true);

      expect(find.text('ai_chat.offline_banner'), findsOneWidget);
      expect(find.text('ai_chat.send_failed_banner'), findsNothing);
    });
  });
}

final class _RecordingHandler extends AiActionHandler {
  _RecordingHandler(this.type, this.calls);

  @override
  final AiUiActionType type;

  final List<AiUiAction> calls;

  @override
  void handle(BuildContext context, AiUiAction action) => calls.add(action);
}

final class _RecordingSink implements AiUiInteractionSink {
  const _RecordingSink(this.submissions, this.ledger);

  final List<AiUiInteraction> submissions;
  final AiUiInteractionLedger ledger;

  @override
  void submit(AiUiInteraction interaction) {
    submissions.add(interaction);
    ledger.resolve(interaction.nodeId, interaction.status);
  }
}
