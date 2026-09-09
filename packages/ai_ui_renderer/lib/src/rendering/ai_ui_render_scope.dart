import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/actions/ai_action_registry.dart';
import 'package:ai_ui_renderer/src/diagnostics/ai_ui_diagnostics_sink.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_id.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_ledger.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_sink.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_renderer_registry.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_strings.dart';
import 'package:ai_ui_renderer/src/resolvers/ai_asset_resolver.dart';
import 'package:ai_ui_renderer/src/resolvers/ai_icon_resolver.dart';
import 'package:flutter/widgets.dart';

/// Everything a renderer needs, threaded down the tree by constructor.
///
/// Deliberately *not* an `InheritedWidget` lookup per node: `AiUiSurface` reads
/// the environment once and passes this down, so drawing a 100-node tree does
/// no ancestor walks at all. [depth] rides along so a renderer can reason about
/// its position without re-walking the document.
///
/// [interactions], [ledger] and [messageId] ride along for the same reason:
/// answering a card needs the sink, the lifecycle and the id of the message
/// that asked, and a per-node ancestor lookup for any of the three would undo
/// the property above.
final class AiUiRenderScope {
  const AiUiRenderScope({
    required this.registry,
    required this.actions,
    required this.assets,
    required this.icons,
    required this.diagnostics,
    required this.ledger,
    this.interactions = const NoopAiUiInteractionSink(),
    this.messageId,
    this.strings = AiUiStrings.fallback,
    this.depth = 0,
  });

  final AiUiRendererRegistry registry;
  final AiActionRegistry actions;
  final AiAssetResolver assets;
  final AiIconResolver icons;
  final AiUiDiagnosticsSink diagnostics;
  final AiUiStrings strings;

  /// Where a user's answer goes. See [submitInteraction].
  final AiUiInteractionSink interactions;

  /// The answer lifecycle of every node on this surface.
  final AiUiInteractionLedger ledger;

  /// The assistant message that delivered this document, when the host knows
  /// it. Travels on every result so the agent can correlate an answer with the
  /// question it asked.
  final String? messageId;

  final int depth;

  AiUiRenderScope descend() => AiUiRenderScope(
    registry: registry,
    actions: actions,
    assets: assets,
    icons: icons,
    diagnostics: diagnostics,
    ledger: ledger,
    interactions: interactions,
    messageId: messageId,
    strings: strings,
    depth: depth + 1,
  );

  /// Turns [action] into a tap callback, or `null` when there is no action —
  /// which is what makes an un-actioned card non-tappable rather than tappable
  /// and inert.
  VoidCallback? onTapFor(BuildContext context, AiUiAction? action) {
    if (action == null) return null;
    return () => actions.dispatch(context, action);
  }

  /// Sends one structured answer back to the agent.
  ///
  /// The single submission path for every interactive node, and the only place
  /// duplicate submission is prevented: the ledger has to accept the node
  /// before anything is built or sent, so a second tap — or a tap while the
  /// first send is still in flight — returns here and does nothing.
  ///
  /// ## Who resolves the lifecycle
  ///
  /// This method leaves the node `pending`. Resolving it to `submitted` or
  /// `failed` belongs to the sink, which is the only party that knows whether
  /// the send actually happened. The exception is the no-op sink, which
  /// resolves it here because there is nobody else to.
  ///
  /// ## The compatibility fallback
  ///
  /// With a [NoopAiUiInteractionSink] — the design catalog, the showcase page,
  /// a widget test — the interaction's prose is dispatched as a `send_message`
  /// action instead. That is *exactly* what these cards did before results
  /// existed, so a host that has not adopted the sink keeps its old behaviour
  /// without changing a line.
  void submitInteraction(
    BuildContext context, {
    required String nodeId,
    required AiUiInteractionKind kind,
    required AiUiInteractionValue value,
    AiUiNodeType? nodeType,
    AiUiInteractionStatus status = AiUiInteractionStatus.submitted,
    String? text,
  }) {
    if (!ledger.beginSubmission(nodeId)) return;

    final interaction = AiUiInteraction(
      interactionId: mintAiUiInteractionId(),
      nodeId: nodeId,
      kind: kind,
      value: value,
      nodeType: nodeType,
      messageId: messageId,
      status: status,
      text: text,
      createdAt: DateTime.now(),
    );

    final sink = interactions;
    if (sink is NoopAiUiInteractionSink) {
      if (text != null && text.isNotEmpty) {
        actions.dispatch(
          context,
          AiUiAction(
            type: AiUiActionType.sendMessage,
            params: {'text': text},
          ),
        );
      }
      ledger.resolve(nodeId, status);
      return;
    }

    sink.submit(interaction);
  }

  /// Dispatches a capability request that a node owns, and claims the node
  /// while the app runs it.
  ///
  /// Distinct from [submitInteraction] because the *outcome* is not known
  /// here: tapping "Allow" opens a platform dialog, tapping a media option
  /// opens a picker, and only the app learns how either ended. The node id and
  /// message id ride along in [AiUiInteractionParams] so the app's handler can
  /// build a result correlated with the question that asked.
  ///
  /// The node is claimed only when a real sink is present. With the no-op sink
  /// nothing will ever resolve the claim, and leaving a permission card
  /// permanently disabled after one tap would be a regression in exactly the
  /// hosts — the catalog, the showcase — that have no agent to answer.
  void requestCapability(
    BuildContext context, {
    required String nodeId,
    required AiUiAction action,
  }) {
    final tracked = interactions is! NoopAiUiInteractionSink;
    if (tracked && !ledger.beginSubmission(nodeId)) return;

    actions.dispatch(
      context,
      AiUiAction(
        type: action.type,
        params: {
          ...action.params,
          AiUiInteractionParams.nodeId: nodeId,
          if (messageId != null) AiUiInteractionParams.messageId: messageId!,
        },
        routeParams: action.routeParams,
      ),
    );
  }

  /// [requestCapability] as a tap callback, for a control that may be absent.
  VoidCallback? onCapabilityTap(
    BuildContext context, {
    required String nodeId,
    required AiUiAction action,
    bool enabled = true,
  }) {
    if (!enabled) return null;
    return () => requestCapability(context, nodeId: nodeId, action: action);
  }

  /// The recursion point for every container renderer.
  ///
  /// Wraps the child renderer in a try/catch so one bad subtree degrades to
  /// nothing instead of taking down the bubble. This is a second line of
  /// defence only — renderers operate on validated data, so reaching the catch
  /// means a renderer bug, and it is reported as `rendererFailure` rather than
  /// swallowed.
  ///
  /// Note the honest limit: this catches throws during *widget construction*,
  /// not during layout or paint. An app that wants to survive those too should
  /// scope an `ErrorWidget.builder` around the chat page.
  Widget renderChild(BuildContext context, AiUiNode node) {
    final type = node.type;
    final renderer = type == null
        ? registry.fallbackRenderer
        : registry.rendererFor(type);

    if (renderer == null) {
      diagnostics.report(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.unknownNodeType,
          path: node.id,
          nodeType: type?.wire,
          detail: 'no renderer registered',
        ),
      );
      return const SizedBox.shrink();
    }

    try {
      return renderer.build(context, node, this);
    } on Object catch (error) {
      diagnostics.report(
        AiUiDiagnostic(
          code: AiUiDiagnosticCode.rendererFailure,
          path: node.id,
          nodeType: type?.wire,
          detail: error.runtimeType.toString(),
        ),
      );
      return const SizedBox.shrink();
    }
  }

  /// Renders [children] one level deeper. Container renderers call this rather
  /// than [renderChild] directly so [depth] stays accurate.
  List<Widget> renderChildren(
    BuildContext context,
    List<AiUiNode> children,
  ) {
    final scope = descend();
    return [
      for (final child in children) scope.renderChild(context, child),
    ];
  }
}
