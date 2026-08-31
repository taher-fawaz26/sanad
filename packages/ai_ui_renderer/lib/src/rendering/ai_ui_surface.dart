import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/actions/ai_action_registry.dart';
import 'package:ai_ui_renderer/src/diagnostics/ai_ui_diagnostics_sink.dart';
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
    this.strings = AiUiStrings.fallback,
  });

  final AiUiRendererRegistry registry;
  final AiActionRegistry actions;
  final AiAssetResolver assets;
  final AiIconResolver icons;
  final AiUiDiagnosticsSink diagnostics;
  final AiUiStrings strings;

  @override
  List<Object?> get props => [
    registry,
    actions,
    assets,
    icons,
    diagnostics,
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
/// back a chat bubble, a home-screen agent card, or a provider-side panel. It
/// takes an [AiUiDocument] — never raw JSON — because parsing belongs at event
/// ingestion, once, not in `build()`.
class AiUiSurface extends StatelessWidget {
  const AiUiSurface({
    required this.document,
    super.key,
    this.gap,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final AiUiDocument document;

  /// Vertical spacing between top-level blocks. Defaults to `AppSpacing.sm`.
  final double? gap;

  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
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
      strings: environment.strings,
      depth: 1,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      spacing: gap ?? AppSpacing.sm,
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
  bool keepUnsupportedNodes = false,
}) => AiUiValidator(
  limits: limits,
  urlPolicy: urlPolicy,
  supportedActions: environment.actions.supportedTypes,
  knownAssetIds: environment.assets.publishedIds,
  options: AiUiValidatorOptions(keepUnsupportedNodes: keepUnsupportedNodes),
);
