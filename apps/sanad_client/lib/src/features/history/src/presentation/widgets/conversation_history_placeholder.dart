import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/history/src/presentation/conversation_history_tokens.dart';

/// The centred illustration-plus-copy block Conversation History shows when
/// the list has nothing in it — Figma `8124:3831`.
///
/// Not `AppGenericEmptyState` (which this screen used while it was a
/// structural placeholder): that component draws a featured-icon tile over
/// the page's own background, where Figma specifies a 220dp composition — a
/// pale green bloom, a lifted white disc, and Iconly's chat glyph — with 24dp
/// Bold copy beneath it. The two share a shape, not a design.
///
/// Used for both empty renderings the screen has: no conversations at all,
/// and a search that matched none. Same composition, different copy, and the
/// caller decides whether a call to action belongs underneath — "Start a
/// Conversation" is the right answer to an empty history and the wrong one to
/// a query that found nothing.
class ConversationHistoryPlaceholder extends StatelessWidget {
  /// Creates the block.
  const ConversationHistoryPlaceholder({
    required this.title,
    required this.description,
    super.key,
  });

  /// The headline, e.g. Figma's "No Previous Conversations".
  final String title;

  /// The supporting paragraph beneath [title].
  final String description;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      // Figma `gap-[32px]` between the illustration and the copy.
      spacing: AppSpacing.xxxl,
      children: [
        const _ConversationHistoryEmptyIllustration(),
        Column(
          mainAxisSize: MainAxisSize.min,
          // Figma `gap-[16px]` between headline and paragraph.
          spacing: AppSpacing.lg,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              // Figma: 24dp Bold on a 32dp line — the design system's
              // `title3` tier, which resolves SemiBold, so the weight is
              // stated. Tracking is zeroed: `title3` carries -0.5% for
              // headings set at page width, and this one is centred at 24dp
              // where the design specifies none.
              style: typography.title3.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                color: colors.textPrimary,
              ),
            ),
            Text(
              description,
              textAlign: TextAlign.center,
              // Figma: 15dp Regular on a 26dp line — see
              // `ConversationHistoryTokens.emptyDescriptionFontSize` for why
              // neither number comes from a token.
              style: typography.smallNormal.copyWith(
                fontSize:
                    ConversationHistoryTokens.emptyDescriptionFontSize.rfs,
                height: ConversationHistoryTokens.emptyDescriptionHeight,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Figma's `Illustration` (`8124:3832`) — three concentric layers in a 220dp
/// square.
///
/// The bloom and the disc are drawn natively rather than from their exported
/// SVGs, and deliberately: both exports are a single `<circle>` each, and the
/// disc's export carries its lift as an SVG `<filter>` drop shadow, which
/// `flutter_svg` does not render — using the file would have silently dropped
/// the one thing that makes the disc read as lifted. Every number here is the
/// export's own (`r`, `fill`, `fill-opacity`, `dy`, `stdDeviation`), so this
/// is the same circle, painted by a renderer that can draw all of it.
///
/// The chat glyph *is* the exported asset — it is real vector art, not a
/// primitive, and nothing about it could be reconstructed faithfully.
class _ConversationHistoryEmptyIllustration extends StatelessWidget {
  const _ConversationHistoryEmptyIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SizedBox.square(
      dimension: responsiveDimension(
        ConversationHistoryTokens.emptyIllustrationSize,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // `8124:3833` — 180dp of 10% `#26A68C` at 55% layer opacity. The
          // green is `MainPalette.shade600`, which the theme exposes as
          // `primary`.
          _Disc(
            diameter: ConversationHistoryTokens.emptyBloomSize,
            color: colors.primary.withValues(
              alpha: ConversationHistoryTokens.emptyBloomAlpha,
            ),
          ),
          // `8124:3834` — 140dp white disc, `#E8ECEB` hairline, lifted.
          _Disc(
            diameter: ConversationHistoryTokens.emptyDiscSize,
            color: colors.surface,
            border: Border.all(color: colors.border),
            shadow: ConversationHistoryTokens.emptyDiscShadow,
          ),
          AppSvgPicture.asset(
            AppSvgs.aiChatHistoryEmptyChat,
            width: responsiveDimension(
              ConversationHistoryTokens.emptyGlyphSize,
            ),
            height: responsiveDimension(
              ConversationHistoryTokens.emptyGlyphSize,
            ),
          ),
        ],
      ),
    );
  }
}

/// One circle of the illustration.
class _Disc extends StatelessWidget {
  const _Disc({
    required this.diameter,
    required this.color,
    this.border,
    this.shadow,
  });

  final double diameter;
  final Color color;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) => Container(
    width: responsiveDimension(diameter),
    height: responsiveDimension(diameter),
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color,
      border: border,
      boxShadow: shadow,
    ),
  );
}
