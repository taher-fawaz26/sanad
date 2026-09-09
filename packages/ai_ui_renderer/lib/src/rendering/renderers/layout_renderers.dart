import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_ui_image_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

final class AiUiDividerRenderer extends AiNodeRenderer<AiUiDividerNode> {
  const AiUiDividerRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiDividerNode node,
    AiUiRenderScope scope,
  ) => Padding(
    padding: EdgeInsets.symmetric(
      vertical: AiUiTokens.spacing(node.spacing) / 2,
    ),
    child: const AppDivider(),
  );
}

final class AiUiSpacerRenderer extends AiNodeRenderer<AiUiSpacerNode> {
  const AiUiSpacerRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiSpacerNode node,
    AiUiRenderScope scope,
  ) => SizedBox(
    height: AiUiTokens.spacing(node.size),
    width: AiUiTokens.spacing(node.size),
  );
}

final class AiUiRowRenderer extends AiNodeRenderer<AiUiRowNode> {
  const AiUiRowRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiRowNode node,
    AiUiRenderScope scope,
  ) {
    final children = scope.renderChildren(context, node.children);
    final gap = AiUiTokens.spacing(node.gap);

    // Row/Wrap are direction-aware, and `start`/`end` are directional in the
    // protocol too, so an Arabic layout mirrors without the agent knowing.
    final content = node.wrap
        ? Wrap(
            alignment: AiUiTokens.wrapAlignment(node.align),
            spacing: gap,
            runSpacing: gap,
            children: children,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: AiUiTokens.mainAxis(node.align),
            crossAxisAlignment: AiUiTokens.crossAxis(node.crossAlign),
            spacing: gap,
            children: children,
          );

    return Semantics(label: node.a11yLabel, child: content);
  }
}

final class AiUiColumnRenderer extends AiNodeRenderer<AiUiColumnNode> {
  const AiUiColumnRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiColumnNode node,
    AiUiRenderScope scope,
  ) => Semantics(
    label: node.a11yLabel,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: AiUiTokens.crossAxis(node.align),
      spacing: AiUiTokens.spacing(node.gap),
      children: scope.renderChildren(context, node.children),
    ),
  );
}

final class AiUiCardRenderer extends AiNodeRenderer<AiUiCardNode> {
  const AiUiCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiCardNode node,
    AiUiRenderScope scope,
  ) {
    final onTap = scope.onTapFor(context, node.action);

    final card = AppSectionCard(
      title: node.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: scope.renderChildren(context, node.children),
      ),
    );

    final toned = node.tone == AiUiTone.neutral
        ? card
        : DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: AppRadius.circularMd,
              border: Border.all(
                color: AiUiTokens.toneColor(context, node.tone),
              ),
            ),
            child: card,
          );

    if (onTap == null) {
      return Semantics(label: node.a11yLabel, child: toned);
    }

    // One Semantics node for the whole card, so a screen reader announces a
    // single destination rather than every child in turn.
    return Semantics(
      label: node.a11yLabel ?? node.title,
      button: true,
      container: true,
      // Material is supplied here rather than assumed from an ancestor: a
      // surface may be rendered anywhere (a bubble, a sheet, a golden test),
      // and an InkWell without a Material ancestor asserts. Transparency keeps
      // the card's own surface colour intact.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circularMd,
          child: toned,
        ),
      ),
    );
  }
}

/// A bounded column, never a nested scrollable — a chat bubble must not
/// contain a second scroll axis. The item cap in `AiUiLimits` is what keeps
/// that safe.
final class AiUiListRenderer extends AiNodeRenderer<AiUiListNode> {
  const AiUiListRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiListNode node,
    AiUiRenderScope scope,
  ) => Semantics(
    label: node.a11yLabel,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpacing.sm,
      children: scope.renderChildren(context, node.children),
    ),
  );
}

final class AiUiListItemRenderer extends AiNodeRenderer<AiUiListItemNode> {
  const AiUiListItemRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiListItemNode node,
    AiUiRenderScope scope,
  ) {
    final leadingIcon = node.leadingIcon == null
        ? null
        : scope.icons.build(
            node.leadingIcon!,
            size: AppDimension.iconMd,
            color: context.appColors.textSecondary,
          );

    return AppEntityListItem(
      title: node.title,
      caption: node.subtitle,
      leading: _leading(context, node, scope, leadingIcon),
      badge: node.badge == null
          ? null
          : AppStatusBadge(
              label: node.badge!.label,
              type: AiUiTokens.badgeType(node.badge!.tone),
              size: AppStatusBadgeSize.compact,
            ),
      trailing: node.trailingText == null
          ? null
          : Text(
              node.trailingText!,
              style: context.appTypography.smallNormal.copyWith(
                color: context.appColors.textMuted,
              ),
            ),
      onTap: scope.onTapFor(context, node.action),
    );
  }

  Widget? _leading(
    BuildContext context,
    AiUiListItemNode node,
    AiUiRenderScope scope,
    Widget? icon,
  ) {
    final image = node.leadingImage;
    if (image != null) {
      return ClipRRect(
        borderRadius: AppRadius.circularSm,
        child: AiUiImageView(
          source: image,
          scope: scope,
          nodeType: AiUiNodeType.listItem.wire,
          nodeId: node.id,
          width: AppDimension.iconButtonLg,
          height: AppDimension.iconButtonLg,
        ),
      );
    }
    return icon;
  }
}
