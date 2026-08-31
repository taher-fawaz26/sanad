import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Draws the dev-only marker for a node type this client does not know.
///
/// It only ever runs when the validator was configured with
/// `keepUnsupportedNodes: true` — i.e. `!kReleaseMode`. In release the node was
/// already dropped upstream, so users never see this; developers see exactly
/// which type the agent sent, which is the difference between "the card is
/// missing" and "the agent is emitting `service_card_v2`".
final class AiUiUnsupportedRenderer
    extends AiNodeRenderer<AiUiUnsupportedNode> {
  const AiUiUnsupportedRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiUnsupportedNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;

    return Semantics(
      label: scope.strings.unsupportedContent,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: colors.warningContainer,
          borderRadius: AppRadius.circularSm,
          border: Border.all(color: colors.warning),
        ),
        child: Text(
          '${scope.strings.unsupportedContent}: ${node.rawType}',
          style: context.appTypography.tinyNormal.copyWith(
            color: colors.onWarningContainer,
          ),
        ),
      ),
    );
  }
}
