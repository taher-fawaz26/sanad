import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_formatters.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Business-domain renderers.
///
/// These exist so the agent names *what a thing is* — a service, an
/// appointment — instead of reassembling one out of rows and texts. That keeps
/// the payload small, keeps the look consistent, and means the design system
/// can change without a protocol change or a prompt change. When a real
/// `AppServiceCard` lands in the design system, swapping it in is a one-file
/// edit here.
///
/// Note what these renderers do with structured values: they *format* them.
/// The agent sends `{amount, currency}` and an ISO-8601 UTC instant; the
/// client renders them in the device locale. That is why the agent never has
/// to guess how a dirham or an AM/PM time should look in Arabic.
final class AiUiServiceCardRenderer
    extends AiNodeRenderer<AiUiServiceCardNode> {
  const AiUiServiceCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiServiceCardNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final price = node.price;

    return _SemanticCard(
      onTap: scope.onTapFor(context, node.action),
      semanticsLabel: node.a11yLabel ?? node.title,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.md,
        children: [
          if (node.image != null) _Thumb(source: node.image!, scope: scope),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                Row(
                  spacing: AppSpacing.sm,
                  children: [
                    Expanded(
                      child: Text(
                        node.title,
                        style: typography.semiBold(typography.regularNormal),
                      ),
                    ),
                    if (node.badge != null)
                      AppStatusBadge(
                        label: node.badge!.label,
                        type: AiUiTokens.badgeType(node.badge!.tone),
                        size: AppStatusBadgeSize.compact,
                      ),
                  ],
                ),
                if (node.subtitle != null)
                  Text(
                    node.subtitle!,
                    style: typography.smallNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                Row(
                  spacing: AppSpacing.md,
                  children: [
                    if (price != null)
                      Text(
                        AiUiFormatters.money(context, price),
                        style: typography
                            .semiBold(typography.smallNormal)
                            .copyWith(color: colors.primary),
                      ),
                    if (node.ratingValue != null)
                      Text(
                        AiUiFormatters.rating(context, node.ratingValue!),
                        style: typography.smallNormal.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class AiUiAppointmentCardRenderer
    extends AiNodeRenderer<AiUiAppointmentCardNode> {
  const AiUiAppointmentCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiAppointmentCardNode node,
    AiUiRenderScope scope,
  ) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return _SemanticCard(
      onTap: scope.onTapFor(context, node.action),
      semanticsLabel: node.a11yLabel ?? node.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: Text(
                  node.title,
                  style: typography.semiBold(typography.regularNormal),
                ),
              ),
              if (node.status != null)
                AppStatusBadge(
                  label: node.status!,
                  type: AiUiTokens.badgeType(node.statusTone),
                  size: AppStatusBadgeSize.compact,
                ),
            ],
          ),
          Text(
            AiUiFormatters.dateTime(context, node.startsAt),
            style: typography.smallNormal.copyWith(color: colors.textSecondary),
          ),
          if (node.whereText != null)
            Text(
              node.whereText!,
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
        ],
      ),
    );
  }
}

final class AiUiBranchCardRenderer extends AiNodeRenderer<AiUiBranchCardNode> {
  const AiUiBranchCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiBranchCardNode node,
    AiUiRenderScope scope,
  ) => AppEntityListItem(
    title: node.name,
    caption: node.addressText,
    style: AppEntityListItemStyle.compact,
    badge: node.status == null
        ? null
        : AppStatusBadge(
            label: node.status!,
            type: AiUiTokens.badgeType(node.statusTone),
            size: AppStatusBadgeSize.compact,
          ),
    trailing: node.distanceMeters == null
        ? null
        : Text(
            AiUiFormatters.distance(
              context,
              node.distanceMeters!,
              strings: scope.strings,
            ),
            style: context.appTypography.smallNormal.copyWith(
              color: context.appColors.textMuted,
            ),
          ),
    onTap: scope.onTapFor(context, node.action),
  );
}

final class AiUiDocumentCardRenderer
    extends AiNodeRenderer<AiUiDocumentCardNode> {
  const AiUiDocumentCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiDocumentCardNode node,
    AiUiRenderScope scope,
  ) => AppEntityListItem(
    title: node.title,
    leading: Icon(
      Icons.description_outlined,
      size: AppDimension.iconMd,
      color: context.appColors.textSecondary,
    ),
    badge: AppStatusBadge(
      label: node.status,
      type: AiUiTokens.badgeType(node.statusTone),
      size: AppStatusBadgeSize.compact,
    ),
    onTap: scope.onTapFor(context, node.action),
  );
}

/// Suggested replies. Each option posts its own text back as a user turn via
/// `send_message`, so tapping one is indistinguishable from typing it.
final class AiUiQuickReplyRenderer extends AiNodeRenderer<AiUiQuickReplyNode> {
  const AiUiQuickReplyRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiQuickReplyNode node,
    AiUiRenderScope scope,
  ) => Semantics(
    label: node.a11yLabel,
    child: Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in node.options)
          AppChip(
            label: option.label,
            style: AppChipStyle.outline,
            onTap: () => scope.actions.dispatch(context, option.action),
          ),
      ],
    ),
  );
}

/// Shared surface for the card-shaped semantic nodes, so they announce as one
/// target and share one tap treatment.
class _SemanticCard extends StatelessWidget {
  const _SemanticCard({
    required this.child,
    required this.semanticsLabel,
    this.onTap,
  });

  final Widget child;
  final String semanticsLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = AppSectionCard(child: child);
    if (onTap == null) return card;

    return Semantics(
      label: semanticsLabel,
      button: true,
      container: true,
      // See AiUiCardRenderer: the renderer supplies its own Material so it
      // never depends on what it happens to be rendered inside.
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circularMd,
          child: card,
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.source, required this.scope});

  final AiUiImageSource source;
  final AiUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    const size = AiUiTokens.thumbSize;
    final child = switch (source) {
      AiUiRemoteImage(:final url) => AppNetworkImage(
        url,
        width: size,
        height: size,
      ),
      AiUiAssetImage(:final assetId) => _asset(assetId, size),
    };

    return ClipRRect(borderRadius: AppRadius.circularSm, child: child);
  }

  Widget _asset(String assetId, double size) {
    final asset = scope.assets.resolve(assetId);
    if (asset == null) {
      return AppImagePlaceholder(width: size, height: size);
    }
    return asset.isSvg
        ? AppSvgPicture.asset(asset.path, width: size, height: size)
        : Image.asset(
            asset.path,
            package: AppAssets.package,
            width: size,
            height: size,
          );
  }
}
