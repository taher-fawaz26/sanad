import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';

/// Maps a node type to the widget that draws it.
///
/// Keeping this a registry rather than a `switch` over the sealed node
/// hierarchy is a deliberate trade: we give up compile-time exhaustiveness in
/// exchange for being able to add or override a renderer without editing a
/// central file — which is what lets a future `AppServiceCard` replace the
/// composed `service_card` renderer with a one-line change, and lets a test
/// substitute a renderer for one node type only.
final class AiUiRendererRegistry {
  AiUiRendererRegistry({
    Map<AiUiNodeType, AiNodeRenderer<AiUiNode>> renderers = const {},
    this.fallbackRenderer,
  }) {
    _renderers.addAll(renderers);
  }

  final Map<AiUiNodeType, AiNodeRenderer<AiUiNode>> _renderers = {};

  /// Draws [AiUiUnsupportedNode], whose `type` is `null` by definition and so
  /// cannot be keyed like the rest. `null` here means unsupported nodes render
  /// as nothing — the correct behaviour in release, where the validator has
  /// already dropped them anyway.
  final AiNodeRenderer<AiUiNode>? fallbackRenderer;

  /// Registering a type that is already present replaces it. That is the
  /// supported way for an app to specialise one node without forking the
  /// default set.
  void register(AiUiNodeType type, AiNodeRenderer<AiUiNode> renderer) {
    _renderers[type] = renderer;
  }

  AiNodeRenderer<AiUiNode>? rendererFor(AiUiNodeType type) => _renderers[type];

  bool supports(AiUiNodeType type) => _renderers.containsKey(type);

  Set<AiUiNodeType> get supportedTypes => _renderers.keys.toSet();
}
