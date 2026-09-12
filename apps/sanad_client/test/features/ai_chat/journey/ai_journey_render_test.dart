import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_blocks.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_engine.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_fixtures.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/journey/ai_journey_signal.dart';
import 'package:testing/testing.dart';

import 'journey_test_support.dart';

/// What the journey actually puts on screen.
///
/// Every payload goes through the **real** `AiChatConfig.validator` and the
/// **real** `defaultRendererRegistry()` — the same pair the app builds — so a
/// widget can only appear here the way a live agent's payload would make it
/// appear. Nothing constructs an `AiUiDocument` by hand, and no widget in this
/// file belongs to the mock.
///
/// The point of the file is the negative result: if any stage of the journey
/// were drawn by something invented for it, these renders would be showing a
/// widget the production surface does not have.
void main() {
  final validator = AiChatConfig.validator(keepUnsupportedNodes: false);
  late List<AiUiAction> dispatched;
  late List<AiUiInteraction> submitted;
  late AiUiEnvironment environment;
  late AiUiInteractionLedger ledger;

  tearDown(() => ledger.dispose());

  setUp(() {
    dispatched = [];
    submitted = [];
    // A real ledger, because the cards read it: `AiInteractionGate` disables a
    // control whose node has already been answered, and without one the gate
    // has nothing to consult.
    ledger = AiUiInteractionLedger();
    environment = AiUiEnvironment(
      registry: defaultRendererRegistry(),
      ledger: ledger,
      actions: AiActionRegistry([
        for (final type in AiChatConfig.supportedActions)
          _RecordingHandler(type, dispatched.add),
      ]),
      interactions: _RecordingSink(submitted.add),
      // Defaults throughout: these name *client* affordances, and which words
      // the app chooses for them is not what this file is about.
    );
  });

  /// Renders one turn's blocks exactly as a chat bubble does.
  Future<AiUiDocument> render(
    WidgetTester tester,
    List<Map<String, dynamic>> blocks,
  ) async {
    final result = validator.validate(journeyPayload(blocks));
    expect(
      result.diagnostics,
      isEmpty,
      reason: 'the journey must not emit a payload the app would refuse',
    );

    await pumpDsWidget(
      tester,
      AiUiHost(
        environment: environment,
        child: SingleChildScrollView(
          child: AiUiSurface(document: result.document!),
        ),
      ),
    );
    await tester.pump();
    return result.document!;
  }

  /// Scrolls a control into view before tapping it.
  ///
  /// These cards are taller than the default test viewport, and a tap that
  /// lands outside it silently hits nothing — which would read here as "the
  /// card does not dispatch" when in fact it was never pressed.
  Future<void> tapControl(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pump();
  }

  group('each stage renders through the shipped renderer', () {
    final stages = <String, List<Map<String, dynamic>>>{
      'location': [journeyLocationPickerBlock()],
      'permission': [journeyCameraPermissionBlock()],
      'media': [journeyMediaRequestBlock()],
      'search': [journeyProviderSearchBlock()],
      'offer': [journeyProviderOfferBlock()],
      'booking': [journeyBookingSummaryBlock(), journeyBookingConfirmBlock()],
      'appointment': [journeyAppointmentBlock()],
      'payment': [journeyPaymentReceiptBlock()],
      'reminder': [journeyReminderBlock()],
      'verification': [journeyVerificationCodeBlock()],
      'review': [journeyReviewRequestBlock()],
    };

    for (final entry in stages.entries) {
      testWidgets('${entry.key} draws without error', (tester) async {
        await render(tester, entry.value);

        expect(tester.takeException(), isNull);
        // The fallback renderer is what a node with no renderer produces. Its
        // absence is the assertion: nothing here degraded.
        expect(find.byType(AiUiUnsupportedRenderer), findsNothing);
      });
    }
  });

  group('the cards carry the story, not placeholder copy', () {
    testWidgets('the provider card names the fixture provider', (tester) async {
      await render(tester, [journeyProviderOfferBlock()]);

      expect(find.text(AiJourneyFixtures.providerName), findsWidgets);
      expect(find.text(AiJourneyFixtures.providerRole), findsWidgets);
      expect(find.textContaining('Accept Offer'), findsWidgets);
    });

    testWidgets('the verification code is the one the story uses', (
      tester,
    ) async {
      final document = await render(tester, [journeyVerificationCodeBlock()]);

      // Asserted on the node rather than on rendered text: the renderer sets
      // the digits in their own boxes, so there is no single Text to match —
      // and which of those the renderer chooses is its business, not the
      // journey's.
      final node = document.blocks.single as AiUiVerificationCodeNode;
      expect(node.code, AiJourneyFixtures.verificationCode);
      expect(tester.takeException(), isNull);
    });

    testWidgets('booking_summary and confirm_prompt share one document', (
      tester,
    ) async {
      final document = await render(tester, [
        journeyBookingSummaryBlock(),
        journeyBookingConfirmBlock(),
      ]);

      // One document, two blocks, drawn together in one turn — which is how the
      // production protocol expects a summary and its confirmation to arrive.
      expect(document.blocks.map((b) => b.type?.wire), [
        'booking_summary',
        'confirm_prompt',
      ]);
      expect(find.textContaining(AiJourneyFixtures.priceLabel), findsWidgets);
    });
  });

  group('the cards answer back through the real interaction contract', () {
    testWidgets('accepting an offer mints offer_resolved', (tester) async {
      await render(tester, [journeyProviderOfferBlock()]);

      await tapControl(tester, find.text('Accept Offer').first);

      final interaction = submitted.single;
      expect(interaction.kind, AiUiInteractionKind.offerResolved);
      expect(interaction.nodeId, 'journey_provider_offer_0');
      expect(
        (interaction.value as AiUiOfferValue).decision,
        AiUiOfferDecision.accepted,
      );

      // And the engine reads it. This is the loop the whole change is about:
      // the renderer produced the value, and the agent continued from it.
      final engine = AiJourneyEngine()
        ..respond(const AiJourneyTextSignal('home cleaning'))
        ..respond(AiJourneyInteractionSignal(locationSelected()))
        ..respond(AiJourneyInteractionSignal(permissionResult()))
        ..respond(AiJourneyInteractionSignal(mediaResult()));

      expect(
        typesOf(engine.respond(AiJourneyInteractionSignal(interaction))),
        ['booking_summary', 'confirm_prompt'],
      );
    });

    testWidgets('the location picker asks the app for the map', (tester) async {
      await render(tester, [journeyLocationPickerBlock()]);

      await tapControl(tester, find.textContaining('current location').first);

      // Not a location the card invented: it states an intent, and the app's
      // own capability owns the map. That is the seam the real Maps picker
      // plugs into.
      expect(
        dispatched.map((a) => a.type),
        contains(AiUiActionType.requestLocationShare),
      );
    });

    testWidgets('the media request asks the app for the picker', (
      tester,
    ) async {
      await render(tester, [journeyMediaRequestBlock()]);

      await tapControl(tester, find.textContaining('Choose photos').first);

      expect(
        dispatched.map((a) => a.type),
        contains(AiUiActionType.requestImageUpload),
      );
    });

    testWidgets('the permission card asks the app for the platform prompt', (
      tester,
    ) async {
      await render(tester, [journeyCameraPermissionBlock()]);

      await tapControl(tester, find.text('Allow camera').first);

      expect(
        dispatched.map((a) => a.type),
        contains(AiUiActionType.requestPermission),
      );
    });
  });
}

/// Records a dispatch instead of touching the device.
///
/// The capabilities themselves are covered in `ai_chat_capabilities_test`; what
/// matters here is only that the card reaches an app-owned handler at all.
final class _RecordingHandler extends AiActionHandler {
  const _RecordingHandler(this.type, this.onAction);

  @override
  final AiUiActionType type;

  final void Function(AiUiAction) onAction;

  @override
  void handle(BuildContext context, AiUiAction action) => onAction(action);
}

final class _RecordingSink implements AiUiInteractionSink {
  const _RecordingSink(this.onSubmit);

  final void Function(AiUiInteraction) onSubmit;

  @override
  void submit(AiUiInteraction interaction) => onSubmit(interaction);
}
