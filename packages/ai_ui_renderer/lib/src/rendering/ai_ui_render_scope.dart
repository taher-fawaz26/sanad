import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/actions/ai_action_registry.dart';
import 'package:ai_ui_renderer/src/diagnostics/ai_ui_diagnostics_sink.dart';
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
final class AiUiRenderScope {
  const AiUiRenderScope({
    required this.registry,
    required this.actions,
    required this.assets,
    required this.icons,
    required this.diagnostics,
    this.strings = AiUiStrings.fallback,
    this.depth = 0,
  });

  final AiUiRendererRegistry registry;
  final AiActionRegistry actions;
  final AiAssetResolver assets;
  final AiIconResolver icons;
  final AiUiDiagnosticsSink diagnostics;
  final AiUiStrings strings;
  final int depth;

  AiUiRenderScope descend() => AiUiRenderScope(
    registry: registry,
    actions: actions,
    assets: assets,
    icons: icons,
    diagnostics: diagnostics,
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
