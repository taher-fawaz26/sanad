import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_formatters.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards that read a set of values back to the user — a booking about to
/// be confirmed, a request about to be submitted, a payment already taken.

/// `booking_summary` — Figma `action-card` (`7866:8400`).
///
/// Figma runs a rule under the header and pads the footer separately from the
/// body, so this card takes its padding row by row instead of letting
/// [AiSemanticCard] inset everything uniformly.
class AiUiBookingSummaryRenderer
    extends AiNodeRenderer<AiUiBookingSummaryNode> {
  /// Creates the renderer.
  const AiUiBookingSummaryRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiBookingSummaryNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = BorderRadius.circular(AiCardTokens.cardRadius);

    return Semantics(
      container: true,
      label: node.a11yLabel ?? node.title,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: radius,
          border: Border.all(color: colors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (node.title != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(color: colors.border),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    node.title!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .bold(typography.smallNone)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: AiDetailRows(items: node.items, dense: true),
            ),
            if (node.actions.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: AiCardActionRow(actions: node.actions, scope: scope),
              ),
          ],
        ),
      ),
    );
  }
}

/// `request_summary` — Figma `details-card` (`7998:34174`).
class AiUiRequestSummaryRenderer
    extends AiNodeRenderer<AiUiRequestSummaryNode> {
  /// Creates the renderer.
  const AiUiRequestSummaryRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiRequestSummaryNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AiSemanticCard(
      semanticsLabel:
          node.a11yLabel ?? node.summaryTitle ?? node.items.first.value,
      panel: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          // Figma nests white value tiles inside a tinted container, which is
          // what separates the facts from the prose beneath them.
          Container(
            padding: EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(AiCardTokens.tileRadius),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: [
                for (final item in node.items) AiDetailTile(item: item),
              ],
            ),
          ),
          if (node.summaryTitle != null || node.summaryText != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: [
                if (node.summaryTitle != null)
                  Text(
                    node.summaryTitle!,
                    style: typography
                        .semiBold(typography.smallNone)
                        .copyWith(color: colors.textPrimary),
                  ),
                if (node.summaryText != null)
                  Text(
                    node.summaryText!,
                    style: typography
                        .medium(typography.tinyNormal)
                        .copyWith(
                          color: colors.textSecondary,
                        ),
                  ),
              ],
            ),
          if (node.location != null)
            AiMapsLinkRow(
              location: node.location!,
              linkLabel: scope.strings.openInMaps,
              scope: scope,
            ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// `payment_receipt` — Figma `receipt-card` (`8015:29457`).
class AiUiPaymentReceiptRenderer
    extends AiNodeRenderer<AiUiPaymentReceiptNode> {
  /// Creates the renderer.
  const AiUiPaymentReceiptRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiPaymentReceiptNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          AiCardHeader(
            leading: AiToneDisc(
              tone: node.statusTone,
              icon: _glyphFor(node.statusTone),
            ),
            title: node.title,
            subtitle: node.subtitle,
          ),
          if (node.items.isNotEmpty || node.total != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: [
                if (node.items.isNotEmpty)
                  AiDetailRows(items: node.items, dense: true),
                if (node.total != null) ...[
                  const AppDivider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          node.total!.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography
                              .semiBold(typography.smallNone)
                              .copyWith(color: colors.textPrimary),
                        ),
                      ),
                      Flexible(
                        child: Text(
                          AiUiFormatters.money(context, node.total!.amount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                          style: typography
                              .bold(typography.regularNone)
                              .copyWith(color: AiUiTokens.accent(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }

  /// The disc's glyph follows the tone, so a failed payment does not show a
  /// tick in a red circle.
  static IconData _glyphFor(AiUiTone tone) => switch (tone) {
    AiUiTone.error => Icons.close_rounded,
    AiUiTone.warning => Icons.schedule_rounded,
    _ => Icons.check_rounded,
  };
}
