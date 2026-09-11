import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The pieces the two notice cards are assembled from — Figma
/// `system-context-router-card` and `location-outside-service-area`.
///
/// Companion to `ai_card_content.dart` and `ai_status_parts.dart`, split from
/// both for the same reason they are split from each other: these are the
/// parts that only the *notices* use, and adding them to either of those
/// files would grow a file that is already long with shapes no other card
/// draws.
///
/// Nothing here positions anything with `left`/`right`. Every block is a
/// `Row`, every inset is `EdgeInsetsDirectional`, and the one value that is
/// inherently left-to-right — a request reference — is wrapped in
/// `String.ltrIsolated` rather than forced with a `TextDirection`.

/// A full-width chip naming what this conversation already belongs to —
/// Figma's `active-request-context` ("Tied to Active Request: Plumbing Repair
/// (#SND-4821)").
///
/// Flush against the card's inner edges and filled with the neutral control
/// tint, so it reads as a *frame around the conversation* rather than as one
/// more fact inside the card.
class AiContextChip extends StatelessWidget {
  /// Creates the chip.
  const AiContextChip({required this.label, this.icon, super.key});

  /// Prose the agent composed: it names the other request, and only the agent
  /// knows what to call it.
  final String label;

  /// Leading glyph. Defaults to the folder Figma draws.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.controlFill,
        borderRadius: BorderRadius.circular(AiCardTokens.noticeTileRadius),
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Icon(
            icon ?? Icons.folder_outlined,
            size: AiCardTokens.discGlyphSize,
            color: colors.textSecondary,
          ),
          Expanded(
            child: Text(
              label,
              // Two lines, because this is a sentence carrying a service name
              // and a reference and it wraps on every device Figma draws.
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography
                  .semiBold(typography.tinyTight)
                  .copyWith(color: colors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

/// The saved-draft tile — Figma's `draft-badge`.
///
/// Success-tinted with its own border, because what it says is *reassuring*:
/// the words the user typed were kept, and they will not have to type them
/// again. The quote is italic for the same reason it is in Figma — it is the
/// user's own sentence being read back, not the assistant's.
class AiDraftTile extends StatelessWidget {
  /// Creates the tile.
  const AiDraftTile({required this.text, this.label, super.key});

  /// Heading — "Draft Saved". Absent draws the quote on its own.
  final String? label;

  /// What the agent held onto, already quoted by the agent.
  final String text;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final background = AiUiTokens.toneContainer(context, AiUiTone.success);
    final foreground = AiUiTokens.onToneContainer(context, AiUiTone.success);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AiCardTokens.noticeTileRadius),
        border: Border.all(color: foreground.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.sm,
        children: [
          Icon(
            Icons.description_outlined,
            size: AiCardTokens.discGlyphSize,
            color: foreground,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (label != null) ...[
                  Text(
                    label!.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .bold(typography.tinyNone)
                        .copyWith(color: foreground, letterSpacing: 0.4),
                  ),
                  SizedBox(height: AppSpacing.xs / 2),
                ],
                Text(
                  text,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: typography.smallTight.copyWith(
                    color: foreground,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A value the card is *about*, in its own bordered tile — the address a
/// coverage notice refused.
///
/// Distinct from `AiSubjectTile`'s title-over-subtitle shape: there is one
/// value here and no label above it, because the prose immediately before the
/// tile already said what it is.
class AiValueTile extends StatelessWidget {
  /// Creates the tile.
  const AiValueTile({required this.value, this.isLtrValue = false, super.key});

  /// Prose the agent already localized.
  final String value;

  /// Set for an inherently left-to-right value, so a leading symbol does not
  /// reorder to the far end under RTL.
  final bool isLtrValue;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        border: Border.all(color: colors.border),
      ),
      child: Text(
        isLtrValue ? value.ltrIsolated : value,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: typography
            .semiBold(typography.smallTight)
            .copyWith(color: colors.textPrimary),
      ),
    );
  }
}

/// The banner a coverage notice leads with — Figma's
/// `Location outside service area` strip.
///
/// **Neutral chrome, expressive glyph.** Figma fills this with the neutral
/// control tint on a hairline and lets the crossed-pin illustration carry the
/// meaning, rather than washing the whole strip amber. So [tone] tints the
/// glyph alone: a warning still reads as a warning, and the sentence beside it
/// stays at full contrast instead of sitting on a coloured field.
class AiNoticeBanner extends StatelessWidget {
  /// Creates the banner.
  const AiNoticeBanner({
    required this.label,
    required this.icon,
    this.tone = AiUiTone.warning,
    super.key,
  });

  /// The headline — one sentence, already localized by the agent.
  final String label;

  /// The illustration. A glyph rather than an asset: the protocol publishes no
  /// illustration for this state, and a bundled one would be a second source
  /// of truth for the same meaning.
  final IconData icon;

  /// Tints [icon].
  final AiUiTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.controlFill,
        borderRadius: BorderRadius.circular(AiCardTokens.cardRadius),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        spacing: AppSpacing.lg,
        children: [
          Icon(
            icon,
            size: AiCardTokens.noticeGlyphSize,
            color: AiUiTokens.toneColor(context, tone),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography
                  .semiBold(typography.smallTight)
                  .copyWith(color: colors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

/// A centred glyph over a centred title and body — the empty state a card
/// draws when the thing it reports on finished with nothing.
///
/// Used by the exhausted `provider_search`. Centred rather than
/// leading-aligned because there is no list under it to line up with, which is
/// the same reading Figma gives it.
class AiCardEmptyState extends StatelessWidget {
  /// Creates the block.
  const AiCardEmptyState({
    required this.title,
    required this.icon,
    this.body,
    super.key,
  });

  final String title;
  final String? body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.lg,
      children: [
        Container(
          width: AiCardTokens.emptyStateDiscSize,
          height: AiCardTokens.emptyStateDiscSize,
          decoration: BoxDecoration(
            color: colors.background,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              icon,
              size: AiCardTokens.emptyStateGlyphSize,
              color: colors.textSecondary,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography
                  .bold(typography.regularNone)
                  .copyWith(color: colors.textPrimary),
            ),
            if (body != null)
              Text(
                body!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: typography.smallTight.copyWith(
                  color: colors.textSecondary,
                ),
              ),
          ],
        ),
      ],
    );
  }
}
