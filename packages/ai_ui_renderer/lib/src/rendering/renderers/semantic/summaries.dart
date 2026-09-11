import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_formatters.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_status_parts.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/confirmation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards that read a set of values back to the user — a booking about to
/// be confirmed, a request about to be submitted, a payment already taken.

/// `booking_summary` — Figma `action-card` (`7866:8400`) and
/// `booking-confirmed-card`.
///
/// Figma runs a rule under the header and pads the footer separately from the
/// body, so this card takes its padding row by row instead of letting
/// [AiSemanticCard] inset everything uniformly.
///
/// **Two readings of one node.** Without `statusText` this is a set of values
/// the user is about to agree to, and its rows read as a table — label at the
/// start, value at the end. With one it is a booking that has *happened*, and
/// Figma stacks each value under its own label so an address or a reference
/// can wrap. Which reading applies is a property of the data, not a second
/// node type: the same booking is being described either way.
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
    final confirmed = node.statusText != null;
    final heading = node.statusText ?? node.title;

    return Semantics(
      container: true,
      label: node.a11yLabel ?? heading,
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
            if (heading != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(color: colors.border),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    spacing: AppSpacing.sm,
                    children: [
                      if (confirmed)
                        Icon(
                          _statusGlyph(node.statusTone),
                          size: AiCardTokens.discGlyphSize,
                          color: AiUiTokens.toneColor(
                            context,
                            node.statusTone,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          heading,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: typography
                              .bold(typography.smallNone)
                              .copyWith(color: colors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (node.provider != null)
              DecoratedBox(
                decoration: BoxDecoration(
                  border: BorderDirectional(
                    bottom: BorderSide(color: colors.border),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: _ProviderRow(
                    provider: node.provider!,
                    scope: scope,
                    nodeId: node.id,
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: confirmed
                  ? AiStackedDetails(items: node.items)
                  : AiDetailRows(items: node.items, dense: true),
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

  /// The glyph follows the tone, so a booking that failed does not show a tick.
  static IconData _statusGlyph(AiUiTone tone) => switch (tone) {
    AiUiTone.error => Icons.error_outline_rounded,
    AiUiTone.warning => Icons.schedule_rounded,
    _ => Icons.check_circle_rounded,
  };
}

/// Who is coming, inside a card that is not a `provider_card`.
class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.provider,
    required this.scope,
    required this.nodeId,
  });

  final AiUiProviderRef provider;
  final AiUiRenderScope scope;
  final String nodeId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      spacing: AppSpacing.md,
      children: [
        AiProviderAvatar(
          source: provider.image,
          scope: scope,
          nodeType: AiUiNodeType.bookingSummary.wire,
          nodeId: nodeId,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AiVerifiedName(
                name: provider.name,
                verified: provider.verified,
                verifiedLabel: scope.strings.verifiedLabel,
              ),
              if (provider.roleText != null) ...[
                SizedBox(height: AppSpacing.xs / 2),
                Text(
                  provider.roleText!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.tinyNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
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
          if (node.photos.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.sm,
              children: [
                if (node.photosLabel != null)
                  Text(
                    node.photosLabel!,
                    style: typography
                        .semiBold(typography.smallNone)
                        .copyWith(color: colors.textPrimary),
                  ),
                AiPhotoStrip(
                  photos: node.photos,
                  scope: scope,
                  nodeType: AiUiNodeType.requestSummary.wire,
                  nodeId: node.id,
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
          // Below the generic action row: submitting is the card's conclusion,
          // and anything else it offers is a detour from it.
          if (node.confirm != null)
            AiConfirmChoiceRow(
              choice: node.confirm!,
              nodeId: node.id,
              nodeType: AiUiNodeType.requestSummary,
              scope: scope,
            ),
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
