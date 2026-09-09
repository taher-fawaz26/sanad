import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testing/testing.dart';

/// Records what it was asked to do so a test can assert on dispatch without
/// standing up real navigation.
final class RecordingActionHandler extends AiActionHandler {
  RecordingActionHandler(this.type);

  @override
  final AiUiActionType type;

  final List<AiUiAction> calls = [];

  @override
  void handle(BuildContext context, AiUiAction action) => calls.add(action);
}

/// Records the answers a surface produced, so a test can assert on the
/// structured result rather than only on the sentence it also posts.
final class RecordingAiUiInteractionSink implements AiUiInteractionSink {
  RecordingAiUiInteractionSink(this.ledger);

  final AiUiInteractionLedger ledger;
  final List<AiUiInteraction> submissions = [];

  /// Set to fail the next submission, so a test can drive the failed →
  /// answerable-again path the way a dropped request would.
  bool failNext = false;

  @override
  void submit(AiUiInteraction interaction) {
    submissions.add(interaction);
    if (failNext) {
      failNext = false;
      ledger.markFailed(interaction.nodeId);
      return;
    }
    switch (interaction.status) {
      case AiUiInteractionStatus.submitted:
        ledger.markSubmitted(interaction.nodeId);
      case AiUiInteractionStatus.cancelled:
        ledger.markCancelled(interaction.nodeId);
      case AiUiInteractionStatus.failed:
        ledger.markFailed(interaction.nodeId);
    }
  }
}

final class RendererHarness {
  RendererHarness({
    Set<AiUiActionType> handledActions = const {
      AiUiActionType.sendMessage,
      AiUiActionType.openService,
      AiUiActionType.openAppointment,
      AiUiActionType.openBranch,
      AiUiActionType.openDocument,
      AiUiActionType.openUrl,
      AiUiActionType.copyText,
      AiUiActionType.callPhone,
      AiUiActionType.openMap,
      AiUiActionType.requestPermission,
      AiUiActionType.requestImageUpload,
      AiUiActionType.requestLocationShare,
    },
    bool showUnsupportedMarker = false,
    // Off by default so the existing suites keep exercising the *fallback*
    // path — a host with no sink, which still posts the agent's sentence as a
    // `send_message`. That is the compatibility guarantee, and it is only
    // guaranteed while something tests it.
    bool recordInteractions = false,
  }) : handlers = {
         for (final type in handledActions) type: RecordingActionHandler(type),
       },
       diagnostics = RecordingAiUiDiagnosticsSink() {
    actions = AiActionRegistry(handlers.values);
    interactions = recordInteractions
        ? RecordingAiUiInteractionSink(ledger)
        : null;
    environment = AiUiEnvironment(
      registry: defaultRendererRegistry(
        showUnsupportedMarker: showUnsupportedMarker,
      ),
      actions: actions,
      diagnostics: diagnostics,
      interactions: interactions ?? const NoopAiUiInteractionSink(),
      ledger: ledger,
    );
  }

  final Map<AiUiActionType, RecordingActionHandler> handlers;
  final RecordingAiUiDiagnosticsSink diagnostics;
  final AiUiInteractionLedger ledger = AiUiInteractionLedger();
  late final AiActionRegistry actions;
  late final RecordingAiUiInteractionSink? interactions;
  late final AiUiEnvironment environment;

  List<AiUiAction> callsTo(AiUiActionType type) =>
      handlers[type]?.calls ?? const [];

  /// Every structured answer this surface produced. Empty unless the harness
  /// was built with `recordInteractions: true`.
  List<AiUiInteraction> get submissions =>
      interactions?.submissions ?? const [];

  AiUiNodeInteractionState stateOf(String nodeId) => ledger.stateOf(nodeId);

  /// A validator wired to exactly this harness's allowlists — the same
  /// pairing the app uses, so a test can never accidentally render something
  /// the real validator would have rejected.
  AiUiValidator get validator => validatorFor(
    environment,
    // Gates the `open_url` *action*. Image URLs have their own policy —
    // `imageUrlPolicy`, which defaults to any https host — and
    // `validatorFor` derives knownAssetIds from environment.assets.
    urlPolicy: const AiUiUrlPolicy(allowedHosts: {'cdn.trysanad.us'}),
    keepUnsupportedNodes: environment.registry.fallbackRenderer != null,
  );
}

/// Renders [nodes] through the real validate → render pipeline.
///
/// Going through the validator rather than constructing an `AiUiDocument`
/// directly is deliberate: it means these tests exercise the same path a live
/// payload takes, and a renderer can never be tested against a node shape the
/// validator would not actually produce.
Future<RendererHarness> pumpNodes(
  WidgetTester tester,
  List<Map<String, dynamic>> nodes, {
  RendererHarness? harness,
  TextDirection textDirection = TextDirection.ltr,
  String? messageId,
}) async {
  final active = harness ?? RendererHarness();
  final result = active.validator.validate(<String, dynamic>{
    'schemaVersion': 1,
    'blocks': nodes,
  });
  active.diagnostics.reportAll(result.diagnostics);

  await pumpDsWidget(
    tester,
    AiUiHost(
      environment: active.environment,
      child: Directionality(
        textDirection: textDirection,
        // Scrollable because that is where a surface actually lives — inside
        // the chat's message list, with unbounded height. Without it a tall
        // reply overflows the fixed test viewport and reports a layout error
        // that says nothing about the renderer.
        child: SingleChildScrollView(
          child: AiUiSurface(
            messageId: messageId,
            document:
                result.document ??
                const AiUiDocument(schemaVersion: 1, blocks: []),
          ),
        ),
      ),
    ),
  );
  return active;
}

/// Scrolls [text] into view, then taps it.
///
/// The AI cards are tall — a permission prompt with a map preview, a location
/// picker with saved places — and the test viewport is 800×600, so a control
/// near the bottom of a card starts below the fold. `tester.tap` would aim at
/// a point outside the viewport and hit nothing.
///
/// Scrolling first is also what a user does, so this keeps the interaction
/// honest rather than reaching past the layout.
Future<void> tapText(WidgetTester tester, String text) async {
  final finder = find.text(text);
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
}
