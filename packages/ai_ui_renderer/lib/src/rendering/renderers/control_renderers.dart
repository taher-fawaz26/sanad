import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

final class AiUiButtonRenderer extends AiNodeRenderer<AiUiButtonNode> {
  const AiUiButtonRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiButtonNode node,
    AiUiRenderScope scope,
  ) {
    final icon = node.icon == null ? null : scope.icons.build(node.icon!);

    return Semantics(
      label: node.a11yLabel,
      child: AppButton(
        label: node.label,
        // A null callback is how AppButton renders a real disabled state, so
        // `enabled: false` reaches assistive tech as disabled rather than
        // merely looking greyed out.
        onPressed: node.enabled
            ? () => scope.actions.dispatch(context, node.action)
            : null,
        variant: AiUiTokens.buttonVariant(node.variant),
        intent: AiUiTokens.buttonIntent(node.intent),
        size: AiUiTokens.buttonSize(node.size),
        icon: icon,
        iconPosition: icon == null
            ? AppButtonIconPosition.none
            : AppButtonIconPosition.left,
      ),
    );
  }
}

final class AiUiChipRenderer extends AiNodeRenderer<AiUiChipNode> {
  const AiUiChipRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiChipNode node,
    AiUiRenderScope scope,
  ) {
    final icon = node.icon == null
        ? null
        : scope.icons.build(node.icon!, size: AppDimension.iconXs);

    return Semantics(
      label: node.a11yLabel,
      child: AppChip(
        label: node.label,
        selected: node.selected,
        tone: AiUiTokens.chipTone(node.tone),
        icon: icon,
        iconPosition: icon == null
            ? AppChipIconPosition.none
            : AppChipIconPosition.left,
        onTap: scope.onTapFor(context, node.action),
      ),
    );
  }
}

final class AiUiProgressRenderer extends AiNodeRenderer<AiUiProgressNode> {
  const AiUiProgressRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiProgressNode node,
    AiUiRenderScope scope,
  ) {
    final value = node.value;

    // A live region so a screen reader announces progress changing rather
    // than the user having to re-read the bubble.
    return Semantics(
      label: node.a11yLabel ?? node.label,
      liveRegion: true,
      value: value == null ? null : '${(value * 100).round()}%',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.xs,
        children: [
          if (node.label != null)
            Text(
              node.label!,
              style: context.appTypography.smallNormal.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          // Indeterminate progress has no bar to fill, so it degrades to the
          // shared activity indicator rather than a bar stuck at zero.
          if (value == null)
            const AppLoadingIndicator(size: AiUiTokens.loadingGlyphSize)
          else
            AppProgressBar(value: value),
        ],
      ),
    );
  }
}

final class AiUiLoadingRenderer extends AiNodeRenderer<AiUiLoadingNode> {
  const AiUiLoadingRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiLoadingNode node,
    AiUiRenderScope scope,
  ) => Semantics(
    label: node.a11yLabel ?? node.label,
    liveRegion: true,
    child: Row(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        const AppLoadingIndicator(size: AiUiTokens.loadingGlyphSize),
        if (node.label != null)
          Flexible(
            child: Text(
              node.label!,
              style: context.appTypography.smallNormal.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
          ),
      ],
    ),
  );
}
