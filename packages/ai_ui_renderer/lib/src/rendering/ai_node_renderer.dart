import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:flutter/widgets.dart';

/// Draws one node type.
///
/// A renderer is a *total* function over an already-validated node: by the time
/// it runs, required fields are present and correctly typed, enums are known
/// members, actions are on the host's allowlist and URLs passed the URL policy.
/// That is why renderers contain no defensive parsing — the invalid states were
/// made unrepresentable upstream rather than guarded against here.
///
/// Implement [render]; [build] does the type dispatch the registry relies on.
abstract class AiNodeRenderer<T extends AiUiNode> {
  const AiNodeRenderer();

  Widget render(BuildContext context, T node, AiUiRenderScope scope);

  /// Type-safe entry point used by the registry, which stores renderers under
  /// their node type but hands them the base [AiUiNode]. A mismatch renders
  /// nothing rather than throwing — it would mean the registry was mis-keyed,
  /// which is a programming error we should not turn into a user-facing crash.
  Widget build(BuildContext context, AiUiNode node, AiUiRenderScope scope) =>
      node is T ? render(context, node, scope) : const SizedBox.shrink();
}
