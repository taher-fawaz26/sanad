import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/interaction/ai_interaction_gate.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_notice_parts.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_status_parts.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/confirmation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards that report something went differently than planned.
///
/// Both are *statements with a way out*: the agent says what changed and
/// offers the paths forward, and the answer — where the card asks for one —
/// travels through the shared `confirmation_resolved` interaction rather than
/// as a sentence the agent has to re-read. Neither card mutates anything: a
/// tap produces a result, and what happens next is the conversation's.

/// `request_notice` — Figma `system-context-router-card`.
///
/// One renderer for the three readings the component publishes, because the
/// blocks are additive rather than alternative: the status pill and reference
/// row appear when the agent sent them, the context chip and the draft tile
/// appear when it sent those. A card with neither is still the same card with
/// a headline and its controls.
class AiUiRequestNoticeRenderer extends AiNodeRenderer<AiUiRequestNoticeNode> {
  /// Creates the renderer.
  const AiUiRequestNoticeRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiRequestNoticeNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final status = node.status;
    final hasHeader = status != null || node.reference != null;

    return Semantics(
      // The state of a request changed without the user asking, so a screen
      // reader should hear it rather than discover it by exploring.
      liveRegion: true,
      child: AiSemanticCard(
        semanticsLabel:
            node.a11yLabel ??
            [
              status?.label,
              node.title,
              node.body,
            ].nonNulls.join(', '),
        panel: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.lg,
          children: [
            if (hasHeader)
              Row(
                // Both halves flexible rather than a `Spacer` between two
                // unconstrained children, so neither can push the other off
                // the row — and weighted 3:1 rather than evenly, because an
                // even split is what truncated "Booking Cancelled" to
                // "Booking Cance…" on a 393dp device while two thirds of the
                // row sat empty. Two `Flexible`s share the row by flex, not by
                // what they need, so the ratio is the only place to say which
                // one gets the space: the status is the sentence, the
                // reference is a short fixed-format id.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                spacing: AppSpacing.sm,
                children: [
                  if (status != null)
                    Flexible(
                      flex: 3,
                      child: AiStatusPill(
                        label: status.label,
                        tone: status.tone,
                        dot: true,
                      ),
                    ),
                  if (node.reference != null)
                    Flexible(
                      child: Text(
                        // A reference is the SAN-770 value class: without the
                        // isolate its leading `#` renders at the far end under
                        // Arabic.
                        node.reference!.ltrIsolated,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                        style: typography.tinyNone.copyWith(
                          color: colors.textMuted,
                        ),
                      ),
                    ),
                ],
              ),
            if (node.contextLabel != null)
              AiContextChip(label: node.contextLabel!),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                Text(
                  node.title,
                  style: typography
                      .bold(typography.regularNone)
                      .copyWith(color: colors.textPrimary),
                ),
                if (node.body != null) AiCardBody(text: node.body!),
              ],
            ),
            if (node.draftText != null)
              AiDraftTile(text: node.draftText!, label: node.draftLabel),
            if (node.confirm != null || node.actions.isNotEmpty) ...[
              const AppDivider(),
              // The decision and the extra destinations are one control group,
              // so they sit at the same 8dp rhythm as the pills inside each of
              // them. Left to the card's own 16dp gap, the answer and the
              // "Contact Sanad Support" beneath it read as two separate
              // blocks, which is not how Figma groups them.
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                spacing: AppSpacing.sm,
                children: [
                  if (node.confirm != null)
                    AiConfirmChoiceRow(
                      choice: node.confirm!,
                      nodeId: node.id,
                      nodeType: AiUiNodeType.requestNotice,
                      scope: scope,
                      stacked: true,
                    ),
                  if (node.actions.isNotEmpty)
                    AiCardActionRow(
                      actions: node.actions,
                      scope: scope,
                      stacked: true,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// `service_area_notice` — Figma `location-outside-service-area`.
///
/// The banner and the card are one node, not two: the headline names the
/// problem and the card below it names the address and the way out, and an
/// agent able to send one without the other could leave the user with a
/// warning and nothing to act on.
class AiUiServiceAreaNoticeRenderer
    extends AiNodeRenderer<AiUiServiceAreaNoticeNode> {
  /// Creates the renderer.
  const AiUiServiceAreaNoticeRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiServiceAreaNoticeNode node,
    AiUiRenderScope scope,
  ) => Semantics(
    liveRegion: true,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.md,
      children: [
        AiNoticeBanner(
          label: node.title,
          // A pin with a cross through it: the one Material glyph that means
          // *this place is not usable*, rather than a generic warning
          // triangle that would say nothing about location.
          icon: Icons.wrong_location_outlined,
          tone: node.tone,
        ),
        AiSemanticCard(
          semanticsLabel:
              node.a11yLabel ?? '${node.title}. ${node.addressText}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            spacing: AppSpacing.md,
            children: [
              if (node.body != null) AiCardBody(text: node.body!),
              AiValueTile(value: node.addressText),
              if (node.changeLabel != null)
                AiInteractionGate(
                  nodeId: node.id,
                  ledger: scope.ledger,
                  builder: (context, state) => AiPromptButton(
                    label: node.changeLabel!,
                    // The same capability request `location_confirm`'s own
                    // "Change location" makes, so there is one location flow
                    // rather than a second one owned by this card. The app
                    // runs the picker and answers with a `permission_result`
                    // correlated to this node.
                    onTap: scope.onCapabilityTap(
                      context,
                      nodeId: node.id,
                      action: const AiUiAction(
                        type: AiUiActionType.requestLocationShare,
                      ),
                      enabled: state.isInteractive,
                    ),
                  ),
                ),
              if (node.actions.isNotEmpty)
                AiCardActionRow(
                  actions: node.actions,
                  scope: scope,
                  stacked: true,
                ),
            ],
          ),
        ),
      ],
    ),
  );
}
