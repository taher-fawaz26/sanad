import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/actions/ai_action_registry.dart';
import 'package:ai_ui_renderer/src/diagnostics/ai_ui_diagnostics_sink.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_ledger.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_sink.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_renderer_registry.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_strings.dart';
import 'package:ai_ui_renderer/src/resolvers/ai_asset_resolver.dart';
import 'package:ai_ui_renderer/src/resolvers/ai_icon_resolver.dart';
import 'package:design_system/design_system.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

/// The renderer's collaborators, provided once per screen.
final class AiUiEnvironment extends Equatable {
  const AiUiEnvironment({
    required this.registry,
    required this.actions,
    this.assets = const AiAssetResolver.defaults(),
    this.icons = const AiIconResolver(),
    this.diagnostics = const NoopAiUiDiagnosticsSink(),
    this.interactions = const NoopAiUiInteractionSink(),
    this.ledger,
    this.strings = AiUiStrings.fallback,
  });

  final AiUiRendererRegistry registry;
  final AiActionRegistry actions;
  final AiAssetResolver assets;
  final AiIconResolver icons;
  final AiUiDiagnosticsSink diagnostics;

  /// Where a user's answer to a semantic node goes.
  ///
  /// Defaults to [NoopAiUiInteractionSink], which is what keeps a host that
  /// has no agent to answer — the design catalog, the showcase page, a widget
  /// test — rendering and behaving exactly as it did before results existed.
  final AiUiInteractionSink interactions;

  /// The answer lifecycle, shared across every surface on the screen.
  ///
  /// Optional, and **must be owned by something with a lifetime**: the chat
  /// bloc owns one for the conversation, so a card's disabled state survives
  /// scrolling and a failed send can re-enable the right card. A host that
  /// leaves this `null` gets a ledger scoped to each individual surface, which
  /// is enough for duplicate prevention within one card but forgets on
  /// rebuild.
  final AiUiInteractionLedger? ledger;

  final AiUiStrings strings;

  @override
  List<Object?> get props => [
    registry,
    actions,
    assets,
    icons,
    diagnostics,
    interactions,
    ledger,
    strings,
  ];
}

/// Provides an [AiUiEnvironment] to every [AiUiSurface] beneath it.
///
/// Install this once, at the chat page. Each surface then reads it a single
/// time and threads a plain [AiUiRenderScope] down its own tree, so rendering
/// a 100-node document does no per-node ancestor lookups.
class AiUiHost extends InheritedWidget {
  const AiUiHost({
    required this.environment,
    required super.child,
    super.key,
  });

  final AiUiEnvironment environment;

  static AiUiEnvironment of(BuildContext context) {
    final host = context.dependOnInheritedWidgetOfExactType<AiUiHost>();
    assert(host != null, 'AiUiSurface requires an AiUiHost ancestor');
    return host!.environment;
  }

  @override
  bool updateShouldNotify(AiUiHost oldWidget) =>
      environment != oldWidget.environment;
}

/// Renders a validated protocol document.
///
/// Deliberately a plain widget with no chat knowledge: the same surface can
/// back a chat bubble, a home-screen agent card, a live-voice overlay, or a
/// provider-side panel. It takes an [AiUiDocument] — never raw JSON — because
/// parsing belongs at event ingestion, once, not in `build()`.
///
/// Stateful for exactly one reason: a host that supplies no
/// [AiUiEnvironment.ledger] still needs somewhere for node lifecycle to live,
/// and a surface is the right scope for it. One `State` per rendered document
/// — bubbles are already `RepaintBoundary`-wrapped and rebuild rarely, so this
/// is not on any hot path.
class AiUiSurface extends StatefulWidget {
  const AiUiSurface({
    required this.document,
    super.key,
    this.messageId,
    this.gap,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final AiUiDocument document;

  /// The assistant message that delivered [document]. Travels on every answer
  /// so the agent can correlate a result with the question it asked.
  final String? messageId;

  /// Vertical spacing between top-level blocks. Defaults to `AppSpacing.sm`.
  final double? gap;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<AiUiSurface> createState() => _AiUiSurfaceState();
}

class _AiUiSurfaceState extends State<AiUiSurface> {
  AiUiInteractionLedger? _fallbackLedger;

  AiUiInteractionLedger _ledgerFor(AiUiEnvironment environment) =>
      environment.ledger ??
      (_fallbackLedger ??= AiUiInteractionLedger());

  @override
  void dispose() {
    _fallbackLedger?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.document;
    if (document.isEmpty) return const SizedBox.shrink();

    // Read the environment exactly once per surface, then thread it down by
    // constructor — never a lookup per node.
    final environment = AiUiHost.of(context);
    final scope = AiUiRenderScope(
      registry: environment.registry,
      actions: environment.actions,
      assets: environment.assets,
      icons: environment.icons,
      diagnostics: environment.diagnostics,
      ledger: _ledgerFor(environment),
      interactions: environment.interactions,
      messageId: widget.messageId,
      strings: environment.strings,
      depth: 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: widget.crossAxisAlignment,
      spacing: widget.gap ?? AppSpacing.sm,
      children: [
        for (final block in document.blocks) scope.renderChild(context, block),
      ],
    );
  }
}

/// Convenience for the common case: build a validator whose allowlists match
/// this environment exactly.
///
/// Threading the *same* registries into both validation and rendering is what
/// guarantees an action with no handler or an asset with no file is dropped
/// before a widget exists, rather than failing at tap time.
AiUiValidator validatorFor(
  AiUiEnvironment environment, {
  AiUiLimits limits = AiUiLimits.defaults,
  AiUiUrlPolicy urlPolicy = AiUiUrlPolicy.denyAll,
  AiUiUrlPolicy imageUrlPolicy = AiUiUrlPolicy.httpsAnyHost,
  bool keepUnsupportedNodes = false,
}) => AiUiValidator(
  limits: limits,
  urlPolicy: urlPolicy,
  imageUrlPolicy: imageUrlPolicy,
  supportedActions: environment.actions.supportedTypes,
  knownAssetIds: environment.assets.publishedIds,
  options: AiUiValidatorOptions(keepUnsupportedNodes: keepUnsupportedNodes),
);
