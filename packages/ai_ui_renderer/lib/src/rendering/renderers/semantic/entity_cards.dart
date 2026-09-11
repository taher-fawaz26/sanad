import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/interaction/ai_interaction_gate.dart';
import 'package:ai_ui_renderer/src/interaction/ai_ui_interaction_ledger.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_formatters.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_status_parts.dart';
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

/// `provider_card` — Figma `provider-card` (`8015:29509`) and the offer card
/// in both its collapsed and expanded readings.
///
/// The expansion is **widget state seeded by the payload**, not an interaction:
/// `presentation` is where the agent wants the card to start, and which one the
/// reader wants after that is theirs. Nothing about it is reported back, so
/// there is nothing for the ledger to hold — unlike the offer underneath it,
/// which is a question and does go through `submitInteraction`.
class AiUiProviderCardRenderer extends AiNodeRenderer<AiUiProviderCardNode> {
  /// Creates the renderer.
  const AiUiProviderCardRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiProviderCardNode node,
    AiUiRenderScope scope,
  ) => _ProviderCard(node: node, scope: scope, key: ValueKey(node.id));
}

class _ProviderCard extends StatefulWidget {
  const _ProviderCard({required this.node, required this.scope, super.key});

  final AiUiProviderCardNode node;
  final AiUiRenderScope scope;

  @override
  State<_ProviderCard> createState() => _ProviderCardState();
}

class _ProviderCardState extends State<_ProviderCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.node.presentation == AiUiPresentation.expanded;
  }

  /// Whether there is anything the compact reading leaves out.
  ///
  /// Drives the disclosure control's existence rather than its state: a
  /// chevron on a card with nothing more to show is a control that does
  /// nothing, which is worse than no control.
  bool get _hasDetail {
    final node = widget.node;
    return node.description != null ||
        node.services.isNotEmpty ||
        node.photos.isNotEmpty ||
        node.distanceMeters != null;
  }

  void _resolveOffer(AiUiProviderOffer offer, {required bool accepted}) {
    widget.scope.submitInteraction(
      context,
      nodeId: widget.node.id,
      nodeType: AiUiNodeType.providerCard,
      kind: AiUiInteractionKind.offerResolved,
      // The provider's own id travels with the decision so the agent resolves
      // the booking by identifier rather than by matching the name it printed.
      value: AiUiOfferValue(
        decision: accepted
            ? AiUiOfferDecision.accepted
            : AiUiOfferDecision.declined,
        providerId: widget.node.providerId,
        offerId: offer.offerId,
      ),
      text: accepted ? offer.acceptTemplate : offer.declineTemplate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final scope = widget.scope;
    final colors = context.appColors;
    final typography = context.appTypography;
    final showDetail = _expanded && _hasDetail;

    return AiSemanticCard(
      semanticsLabel: node.a11yLabel ?? node.name,
      onTap: scope.onTapFor(context, node.action),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          Row(
            spacing: AppSpacing.md,
            children: [
              AiProviderAvatar(
                source: node.image,
                scope: scope,
                nodeType: AiUiNodeType.providerCard.wire,
                nodeId: node.id,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AiVerifiedName(
                      name: node.name,
                      verified: node.verified,
                      verifiedLabel: scope.strings.verifiedLabel,
                    ),
                    if (node.roleText != null) ...[
                      SizedBox(height: AppSpacing.xs / 2),
                      Text(
                        node.roleText!,
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
              if (node.ratingValue != null)
                AiRatingRow(
                  value: node.ratingValue!,
                  formatted: AiUiFormatters.rating(context, node.ratingValue!),
                  outOfLabel: scope.strings.ratingOutOfFive,
                ),
              if (_hasDetail)
                AiDisclosureButton(
                  expanded: _expanded,
                  label: _expanded
                      ? scope.strings.showLessLabel
                      : scope.strings.showMoreLabel,
                  onTap: () => setState(() => _expanded = !_expanded),
                ),
            ],
          ),
          if (node.proposedTime != null) ...[
            const AppDivider(),
            _LabelledFact(
              icon: Icons.schedule_rounded,
              label: node.proposedTimeLabel,
              value: AiUiFormatters.dateTime(context, node.proposedTime!),
            ),
          ],
          if (showDetail && node.distanceMeters != null) ...[
            const AppDivider(),
            _LabelledFact(
              icon: Icons.straighten_rounded,
              label: scope.strings.distanceLabel,
              value: AiUiFormatters.distance(
                context,
                node.distanceMeters!,
                strings: scope.strings,
              ),
            ),
          ],
          if (node.stats.isNotEmpty) ...[
            const AppDivider(),
            AiStatStrip(stats: node.stats),
          ],
          if (showDetail) ...[
            if (node.description != null)
              AiCardBody(
                text: node.description!,
                emphasised: true,
                maxLines: 8,
              ),
            if (node.services.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  if (node.servicesLabel != null)
                    Text(
                      node.servicesLabel!,
                      style: typography
                          .semiBold(typography.smallNone)
                          .copyWith(color: colors.textPrimary),
                    ),
                  AiTagChips(labels: node.services),
                ],
              ),
            if (node.photos.isNotEmpty)
              AiPhotoStrip(
                photos: node.photos,
                scope: scope,
                nodeType: AiUiNodeType.providerCard.wire,
                nodeId: node.id,
              ),
          ],
          if (node.offer != null)
            _OfferControls(
              offer: node.offer!,
              nodeId: node.id,
              ledger: scope.ledger,
              onResolved: _resolveOffer,
            ),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// A glyph, a muted label and an emphasised value on one row — the proposed
/// time and the distance.
///
/// The 3:4 split is [AiDetailRow]'s, for the same reason: the value takes the
/// larger share and aligns to the trailing edge, so a formatted instant
/// ("19 Nov · 3:00 PM") fits beside a short label instead of ellipsizing. A
/// `Spacer` between the two looked equivalent and was not — it claimed half
/// the free space for itself and truncated the value on a 393dp device.
class _LabelledFact extends StatelessWidget {
  const _LabelledFact({required this.icon, required this.value, this.label});

  final IconData icon;
  final String? label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      spacing: AppSpacing.md,
      children: [
        Icon(
          icon,
          size: AiCardTokens.rowGlyphSize,
          color: colors.textSecondary,
        ),
        Flexible(
          flex: 3,
          child: Text(
            label ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography.tinyNone.copyWith(color: colors.textSecondary),
          ),
        ),
        Expanded(
          flex: 4,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            // A formatted date or distance is one left-to-right run in both
            // languages — the same reason a time slot's label forces it.
            textDirection: AiUiFormatters.valueDirection(value),
            style: typography
                .semiBold(typography.smallNone)
                .copyWith(color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// The accept/decline pair on a card that is an offer.
///
/// Gated on the ledger like every other answerable control: accepting twice
/// would book twice, and the card has to stay legible afterwards as a record
/// of what was agreed.
class _OfferControls extends StatelessWidget {
  const _OfferControls({
    required this.offer,
    required this.nodeId,
    required this.ledger,
    required this.onResolved,
  });

  final AiUiProviderOffer offer;
  final String nodeId;
  final AiUiInteractionLedger ledger;
  final void Function(AiUiProviderOffer offer, {required bool accepted})
  onResolved;

  @override
  Widget build(BuildContext context) => AiInteractionGate(
    nodeId: nodeId,
    ledger: ledger,
    builder: (context, state) => Row(
      spacing: AppSpacing.md,
      children: [
        Expanded(
          child: AiCardButton(
            label: offer.acceptLabel,
            onTap: state.isInteractive
                ? () => onResolved(offer, accepted: true)
                : null,
          ),
        ),
        Expanded(
          child: AiCardButton(
            label: offer.declineLabel,
            variant: AiUiButtonVariant.outline,
            onTap: state.isInteractive
                ? () => onResolved(offer, accepted: false)
                : null,
          ),
        ),
      ],
    ),
  );
}
