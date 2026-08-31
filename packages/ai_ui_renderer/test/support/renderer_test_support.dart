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

final class RendererHarness {
  RendererHarness({
    Set<AiUiActionType> handledActions = const {
      AiUiActionType.sendMessage,
      AiUiActionType.openService,
      AiUiActionType.openAppointment,
      AiUiActionType.openBranch,
      AiUiActionType.openDocument,
      AiUiActionType.openUrl,
    },
    bool showUnsupportedMarker = false,
  }) : handlers = {
         for (final type in handledActions) type: RecordingActionHandler(type),
       },
       diagnostics = RecordingAiUiDiagnosticsSink() {
    actions = AiActionRegistry(handlers.values);
    environment = AiUiEnvironment(
      registry: defaultRendererRegistry(
        showUnsupportedMarker: showUnsupportedMarker,
      ),
      actions: actions,
      diagnostics: diagnostics,
    );
  }

  final Map<AiUiActionType, RecordingActionHandler> handlers;
  final RecordingAiUiDiagnosticsSink diagnostics;
  late final AiActionRegistry actions;
  late final AiUiEnvironment environment;

  List<AiUiAction> callsTo(AiUiActionType type) =>
      handlers[type]?.calls ?? const [];

  /// A validator wired to exactly this harness's allowlists — the same
  /// pairing the app uses, so a test can never accidentally render something
  /// the real validator would have rejected.
  AiUiValidator get validator => validatorFor(
    environment,
    // Images never consult this in v1 (assetId-only); it gates `open_url`.
    // `validatorFor` already derives knownAssetIds from environment.assets.
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
