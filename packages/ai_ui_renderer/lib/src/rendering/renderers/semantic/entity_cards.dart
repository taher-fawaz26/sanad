import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_formatters.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_ui_image_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards that stand for one business object the user can open — a service,
/// an appointment, a branch, a document, an order, a provider.
///
/// All six share [AiSemanticCard] and the attached [AiCardActionRow], so a
/// change to the card language lands in one place rather than six.

/// `service_card` — Figma `service-card` (`7866:8570`).
class AiUiServiceCardRenderer extends AiNodeRenderer<AiUiServiceCardNode> {
  /// Creates the renderer.
  const AiUiServiceCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiServiceCardNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.title,
      onTap: scope.onTapFor(context, node.action),
      // Figma marks the service the conversation is currently about with an
      // accent border rather than a fill, so the card stays readable.
      borderTone: node.selected ? AiUiTone.primary : null,
      emphasised: node.selected,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          // Figma's card has no picture, so the thumbnail appears only when
          // the agent attaches one. Leaving the field accepted-but-unrendered
          // would make a service photo a contract that draws nothing.
          if (node.image != null)
            AiCardThumb(
              source: node.image,
              scope: scope,
              nodeType: AiUiNodeType.serviceCard.wire,
              nodeId: node.id,
            ),
          AiCardTitleRow(title: node.title, badge: node.badge),
          if (node.subtitle != null)
            AiCardBody(text: node.subtitle!, maxLines: 3),
          // Figma puts a single action on the price row as a compact pill
          // rather than a full-width button below it: on this card the price
          // and the way to act on it are one line. Two or more actions still
          // get their own row, because they cannot share the line with a
          // price and stay tappable.
          if (node.price != null ||
              node.ratingValue != null ||
              node.actions.isNotEmpty)
            Row(
              // `spaceBetween` rather than an `Expanded` price: it keeps the
              // pill flush with the trailing edge *and* lets a long label
              // ellipsize instead of overflowing the card, which a non-flex
              // child beside an Expanded one cannot do.
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: AppSpacing.md,
              children: [
                if (node.price != null)
                  Flexible(
                    child: Text(
                      AiUiFormatters.money(context, node.price!),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography
                          .bold(typography.regularNone)
                          .copyWith(color: colors.textPrimary),
                    ),
                  )
                else
                  const Spacer(),
                if (node.ratingValue != null)
                  AiRatingRow(
                    value: node.ratingValue!,
                    formatted: AiUiFormatters.rating(
                      context,
                      node.ratingValue!,
                    ),
                    outOfLabel: scope.strings.ratingOutOfFive,
                  ),
                if (node.actions.length == 1)
                  Flexible(
                    child: AiCardButton(
                      label: node.actions.single.label,
                      variant: node.actions.single.variant,
                      intent: node.actions.single.intent,
                      compact: true,
                      onTap: scope.onTapFor(
                        context,
                        node.actions.single.action,
                      ),
                    ),
                  ),
              ],
            ),
          if (node.actions.length > 1)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// `appointment_card` — Figma `ticket-card` (`7866:8379`) and
/// `detail-action-card` (`7866:8429`).
///
/// One renderer for both frames. They are the same concept: the second simply
/// carries `actions`, and drawing them as two types would mean two payload
/// shapes for one appointment.
class AiUiAppointmentCardRenderer
    extends AiNodeRenderer<AiUiAppointmentCardNode> {
  /// Creates the renderer.
  const AiUiAppointmentCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiAppointmentCardNode node,
    AiUiRenderScope scope,
  ) {
    final when = AiUiFormatters.dateTime(context, node.startsAt);

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? '${node.title}, $when',
      onTap: scope.onTapFor(context, node.action),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          AiCardTitleRow(
            title: node.title,
            large: true,
            badge: node.status == null
                ? null
                : AiUiBadge(label: node.status!, tone: node.statusTone),
          ),
          const AppDivider(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.md,
            children: [
              AiIconRow(
                icon: Icons.calendar_today_outlined,
                text: when,
                emphasised: true,
              ),
              if (node.whereText != null)
                AiIconRow(
                  icon: Icons.location_on_outlined,
                  text: node.whereText!,
                  emphasised: true,
                ),
            ],
          ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// `branch_card` — Figma `branch-card` (`7866:8531`).
class AiUiBranchCardRenderer extends AiNodeRenderer<AiUiBranchCardNode> {
  /// Creates the renderer.
  const AiUiBranchCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiBranchCardNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final distance = node.distanceMeters == null
        ? null
        : AiUiFormatters.distance(
            context,
            node.distanceMeters!,
            strings: scope.strings,
          );

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.name,
      onTap: scope.onTapFor(context, node.action),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          AiCardTitleRow(
            title: node.name,
            badge: node.status == null
                ? null
                : AiUiBadge(label: node.status!, tone: node.statusTone),
          ),
          if (node.addressText != null)
            AiIconRow(
              icon: Icons.location_on_outlined,
              text: node.addressText!,
            ),
          // Distance and opening hours share one row, spread apart — the row
          // renders whenever either half is present.
          if (distance != null || node.hoursText != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    distance == null
                        ? ''
                        : '${scope.strings.distanceLabel}: $distance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.tinyNone.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (node.hoursText != null)
                  Flexible(
                    child: Text(
                      node.hoursText!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: typography.tinyNone.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// `document_card`.
///
/// **Supported, not in the current Figma set.** Kept because it is an
/// already-published backend contract; drawn in the current card language so
/// it does not look like a leftover from the previous design.
class AiUiDocumentCardRenderer extends AiNodeRenderer<AiUiDocumentCardNode> {
  /// Creates the renderer.
  const AiUiDocumentCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiDocumentCardNode node,
    AiUiRenderScope scope,
  ) => AiSemanticCard(
    semanticsLabel: node.a11yLabel ?? '${node.title}, ${node.status}',
    onTap: scope.onTapFor(context, node.action),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.md,
      children: [
        AiCardHeader(
          leading: AiToneDisc(
            tone: node.statusTone,
            icon: Icons.description_outlined,
          ),
          title: node.title,
          trailing: AiCardBadge(
            badge: AiUiBadge(label: node.status, tone: node.statusTone),
          ),
        ),
        if (node.actions.isNotEmpty)
          AiCardActionRow(actions: node.actions, scope: scope),
      ],
    ),
  );
}

/// `order_card` — Figma `order-card` (`7866:8349`).
class AiUiOrderCardRenderer extends AiNodeRenderer<AiUiOrderCardNode> {
  /// Creates the renderer.
  const AiUiOrderCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiOrderCardNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.title,
      onTap: scope.onTapFor(context, node.action),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.md,
        children: [
          AiCardTitleRow(
            title: node.title,
            badge: node.status == null
                ? null
                : AiUiBadge(label: node.status!, tone: node.statusTone),
          ),
          if (node.statusText != null || node.amount != null)
            Row(
              children: [
                Expanded(
                  child: Text(
                    node.statusText ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.smallNone.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                if (node.amount != null)
                  Flexible(
                    child: Text(
                      AiUiFormatters.money(context, node.amount!),
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
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// `provider_card` — Figma `provider-card` (`8015:29509`).
class AiUiProviderCardRenderer extends AiNodeRenderer<AiUiProviderCardNode> {
  /// Creates the renderer.
  const AiUiProviderCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiProviderCardNode node,
    AiUiRenderScope scope,
  ) {
    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.name,
      onTap: scope.onTapFor(context, node.action),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          AiCardHeader(
            leading: _ProviderAvatar(node: node, scope: scope),
            title: node.name,
            subtitle: node.roleText,
            trailing: node.ratingValue == null
                ? null
                : AiRatingRow(
                    value: node.ratingValue!,
                    formatted: AiUiFormatters.rating(
                      context,
                      node.ratingValue!,
                    ),
                    outOfLabel: scope.strings.ratingOutOfFive,
                  ),
          ),
          if (node.stats.isNotEmpty) ...[
            const AppDivider(),
            AiStatStrip(stats: node.stats),
          ],
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// The provider's portrait.
///
/// `AppAvatar` is the design system's avatar and would be the reuse here, but
/// its size tiers are `small` and `medium` and neither is Figma's 48dp; it
/// also takes an `ImageProvider`, where the resolved asset may be an SVG.
/// Falls back to initials the same way `AppAvatar` does.
class _ProviderAvatar extends StatelessWidget {
  const _ProviderAvatar({required this.node, required this.scope});

  final AiUiProviderCardNode node;
  final AiUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: AiCardTokens.avatarSize,
      height: AiCardTokens.avatarSize,
      decoration: BoxDecoration(
        color: colors.controlFill,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      // A provider portrait is backend-owned media, so in practice it arrives
      // as a URL. The person glyph is the no-image state: what a card with
      // neither a URL nor an asset shows, and what a failed download falls
      // back to.
      child: AiUiImageView(
        source: node.image,
        scope: scope,
        nodeType: AiUiNodeType.providerCard.wire,
        nodeId: node.id,
        width: AiCardTokens.avatarSize,
        height: AiCardTokens.avatarSize,
        fallback: Center(
          child: Icon(
            Icons.person_outline_rounded,
            size: AiCardTokens.discGlyphSize,
            color: colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
