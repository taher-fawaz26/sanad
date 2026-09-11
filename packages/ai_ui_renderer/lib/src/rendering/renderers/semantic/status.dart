import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_node_renderer.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_content.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_card_surface.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_notice_parts.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_status_parts.dart';
import 'package:ai_ui_renderer/src/rendering/renderers/semantic/confirmation.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The cards that report where something has got to.
///
/// All three are statements first: what makes them semantic rather than a
/// `card` of primitives is the data underneath — a search the agent can say is
/// running, a lifecycle with typed states, a code with an identity.
///
/// `provider_search` is the one that also *asks*, through the `confirm` block
/// it may carry: acknowledging a running search ("Continue in Background") and
/// answering an exhausted one ("Change Time Slot" / "Cancel") are decisions
/// about that search, so they go through the ledger and the shared
/// `confirmation_resolved` interaction. The other two touch neither, and the
/// only controls they carry are the ordinary `actions` row.

/// `provider_search` — Figma `searching-providers-card` and, for
/// [AiUiProviderSearchState.exhausted], the same `LoadingCard` drawn as its
/// no-match state.
///
/// While searching it is built from the shared loading vocabulary: an
/// indeterminate `progress` draws the design system's activity indicator, a
/// determinate one draws its progress bar. The card adds the *meaning* —
/// which search, and why.
///
/// Exhausted, the indicator goes and a centred empty state leads instead:
/// there is nothing in flight to indicate, and leaving a spinner under "No
/// Specialists Available" would say the opposite of the headline. The controls
/// stack in both readings — see [AiCardActionRow.stacked].
class AiUiProviderSearchRenderer
    extends AiNodeRenderer<AiUiProviderSearchNode> {
  /// Creates the renderer.
  const AiUiProviderSearchRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiProviderSearchNode node,
    AiUiRenderScope scope,
  ) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final progress = node.progress;
    final searching = node.state.isSearching;

    return Semantics(
      // A search that has finished should be announced, not silently swapped
      // for the results underneath it.
      liveRegion: true,
      child: AiSemanticCard(
        semanticsLabel: node.a11yLabel ?? node.title,
        child: Column(
          crossAxisAlignment: searching
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.lg,
          children: [
            if (searching) ...[
              if (node.statusLabel != null)
                AiStatusPill(
                  label: node.statusLabel!,
                  icon: Icons.auto_awesome_rounded,
                ),
              Text(
                node.title,
                style: typography
                    .bold(typography.regularNone)
                    .copyWith(color: colors.textPrimary),
              ),
              if (node.body != null) AiCardBody(text: node.body!, maxLines: 3),
              if (progress == null)
                // Figma's three dots. `AppLoadingIndicator` is the design
                // system's indeterminate glyph and is what every other
                // indeterminate state in the AI surface already draws, so a
                // bespoke dot animation here would be a second spinner.
                const AppLoadingIndicator(size: AiUiTokens.loadingGlyphSize)
              else
                AppProgressBar(value: progress),
            ] else
              AiCardEmptyState(
                title: node.title,
                body: node.body,
                // The trade the search was for. Figma's own glyph for this
                // card, and it says "no *specialists*" where a generic empty
                // box would not.
                icon: Icons.handyman_outlined,
              ),
            if (node.confirm != null)
              AiConfirmChoiceRow(
                choice: node.confirm!,
                nodeId: node.id,
                nodeType: AiUiNodeType.providerSearch,
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
      ),
    );
  }
}

/// `service_timeline` — Figma `timeline-card`.
class AiUiServiceTimelineRenderer
    extends AiNodeRenderer<AiUiServiceTimelineNode> {
  /// Creates the renderer.
  const AiUiServiceTimelineRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiServiceTimelineNode node,
    AiUiRenderScope scope,
  ) {
    final current = node.items.where((item) => item.isCurrent).firstOrNull;

    return AiSemanticCard(
      // The step the user is waiting on is the answer to "where is my
      // service?", so it leads the announcement rather than making a screen
      // reader walk every completed step to find it.
      semanticsLabel:
          node.a11yLabel ??
          [node.title, node.status, current?.title].nonNulls.join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.lg,
        children: [
          if (node.title != null || node.status != null)
            Row(
              children: [
                if (node.title != null)
                  AiStatusPill(
                    label: node.title!,
                    tone: AiUiTone.neutral,
                    bordered: true,
                  ),
                const Spacer(),
                if (node.status != null)
                  AiCardBadge(
                    badge: AiUiBadge(
                      label: node.status!,
                      tone: node.statusTone,
                    ),
                  ),
              ],
            ),
          AiTimeline(items: node.items),
          if (node.actions.isNotEmpty)
            AiCardActionRow(actions: node.actions, scope: scope),
        ],
      ),
    );
  }
}

/// `verification_code` — Figma `verification-code-card`.
///
/// Display-only by design; see [AiUiVerificationCodeNode]. The only control it
/// can carry is its `actions` row, which in practice means a `copy_text`.
class AiUiVerificationCodeRenderer
    extends AiNodeRenderer<AiUiVerificationCodeNode> {
  /// Creates the renderer.
  const AiUiVerificationCodeRenderer();

  @override
  Widget render(
    BuildContext context,
    AiUiVerificationCodeNode node,
    AiUiRenderScope scope,
  ) => AiSemanticCard(
    semanticsLabel: node.a11yLabel ?? node.label ?? node.code,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.lg,
      children: [
        if (node.label != null)
          AiStatusPill(label: node.label!, bordered: true),
        if (node.body != null) AiCardBody(text: node.body!, maxLines: 3),
        AiCodeRow(code: node.code),
        if (node.actions.isNotEmpty)
          AiCardActionRow(actions: node.actions, scope: scope),
      ],
    ),
  );
}
