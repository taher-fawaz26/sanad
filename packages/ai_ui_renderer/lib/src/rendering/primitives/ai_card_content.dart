import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_ui_image_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The pieces every AI semantic card is assembled from.
///
/// Each is used by two or more renderers, which is what earns it a name — a
/// shape used once belongs inline in the renderer that draws it.

/// A card's title, and the badge Figma puts opposite it.
///
/// The title takes the width the badge does not and ellipsizes, so a long
/// service name cannot push the badge out of the card.
class AiCardTitleRow extends StatelessWidget {
  /// Creates the row.
  const AiCardTitleRow({
    required this.title,
    this.badge,
    this.trailing,
    this.large = false,
    super.key,
  });

  final String title;
  final AiUiBadge? badge;

  /// Anything to place opposite the title instead of a badge — a rating, a
  /// timestamp. Ignored when [badge] is set.
  final Widget? trailing;

  /// Figma's 18dp appointment title, against 16dp everywhere else.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final base = large ? typography.largeNone : typography.regularNone;
    final opposite = badge != null ? AiCardBadge(badge: badge!) : trailing;

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography
                .bold(base)
                .copyWith(
                  color: context.appColors.textPrimary,
                ),
          ),
        ),
        if (opposite != null) ...[
          SizedBox(width: AppSpacing.sm),
          opposite,
        ],
      ],
    );
  }
}

/// A short status pill on a card header.
///
/// Colours come from the design system's semantic container pairs — the same
/// `successContainer` / `onSuccessContainer` that `AppStatusBadge` resolves —
/// but the geometry is the AI card's own. `AppStatusBadge` pads 16/8 at every
/// size tier, which on a card header competes with the title it sits beside,
/// and that padding is not parameterised.
///
/// It also handles `tone: primary`, the brand tint Figma uses for `POPULAR`.
/// `AppStatusBadgeType` has no brand member, and adding one would restyle
/// badges across both apps.
class AiCardBadge extends StatelessWidget {
  /// Creates the pill.
  const AiCardBadge({required this.badge, super.key});

  final AiUiBadge badge;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AiUiTokens.toneContainer(context, badge.tone),
        borderRadius: BorderRadius.circular(AiCardTokens.badgeRadius),
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs / 2,
        ),
        child: Text(
          badge.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography
              .semiBold(typography.tinyNone)
              .copyWith(
                color: AiUiTokens.onToneContainer(context, badge.tone),
              ),
        ),
      ),
    );
  }
}

/// The tinted disc that leads a receipt's or a reminder's header.
class AiToneDisc extends StatelessWidget {
  /// Creates the disc around [icon].
  const AiToneDisc({required this.tone, required this.icon, super.key});

  final AiUiTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
    width: AiCardTokens.discSize,
    height: AiCardTokens.discSize,
    decoration: BoxDecoration(
      color: AiUiTokens.toneContainer(context, tone),
      shape: BoxShape.circle,
    ),
    child: Center(
      child: Icon(
        icon,
        size: AiCardTokens.discGlyphSize,
        color: AiUiTokens.onToneContainer(context, tone),
      ),
    ),
  );
}

/// A header block: a leading disc or avatar, then a title over a subtitle.
class AiCardHeader extends StatelessWidget {
  /// Creates the header.
  const AiCardHeader({
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      spacing: AppSpacing.md,
      children: [
        if (leading != null) leading!,
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography
                          .bold(typography.regularNone)
                          .copyWith(color: colors.textPrimary),
                    ),
                  ),
                  if (trailing != null) ...[
                    SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
              if (subtitle != null) ...[
                SizedBox(height: AppSpacing.xs / 2),
                Text(
                  subtitle!,
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

/// A card's secondary prose — a service description, a reminder's body.
class AiCardBody extends StatelessWidget {
  /// Creates the paragraph.
  const AiCardBody({
    required this.text,
    this.emphasised = false,
    this.maxLines = 4,
    super.key,
  });

  final String text;

  /// `true` draws it at the card's primary text colour — Figma's reminder
  /// body, which is the point of the card rather than a caption under it.
  final bool emphasised;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Text(
      text,
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      style: (emphasised ? typography.smallNormal : typography.smallTight)
          .copyWith(
            color: emphasised ? colors.textPrimary : colors.textSecondary,
          ),
    );
  }
}

/// A row of label-and-value pairs — the body of every summary and receipt.
///
/// Renders each pair with the label at the start and the value at the end, so
/// the block mirrors under RTL with no payload change. A value marked
/// `isLtrValue` is wrapped in Unicode bidi isolates, which is what stops a
/// reference id's leading symbol reordering to the far end in Arabic.
class AiDetailRows extends StatelessWidget {
  /// Creates the block.
  const AiDetailRows({required this.items, this.dense = false, super.key});

  final List<AiUiDetailItem> items;

  /// Figma's tighter 13dp treatment, used inside the summary cards.
  final bool dense;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.md,
    children: [
      for (final item in items) AiDetailRow(item: item, dense: dense),
    ],
  );
}

/// One label-and-value pair.
class AiDetailRow extends StatelessWidget {
  /// Creates the row.
  const AiDetailRow({required this.item, this.dense = false, super.key});

  final AiUiDetailItem item;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final base = dense ? typography.tinyNone : typography.smallNone;
    final valueColor = item.valueTone == AiUiTone.neutral
        ? colors.textPrimary
        : AiUiTokens.toneColor(context, item.valueTone);

    // Figma pins the value to the card's trailing edge, which two loose
    // `Flexible`s cannot do — they pack both children against the start. The
    // value therefore takes the remaining width and aligns its text to `end`,
    // and the 3:4 split leaves room for a long value ("Apple Pay (•••• 4920)")
    // without letting a long label ellipsize early.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 3,
          child: Text(
            item.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: base.copyWith(color: colors.textSecondary),
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 4,
          child: Text(
            item.isLtrValue ? item.value.ltrIsolated : item.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
            style:
                (item.valueTone == AiUiTone.neutral
                        ? typography.semiBold(base)
                        : typography.bold(base))
                    .copyWith(color: valueColor),
          ),
        ),
      ],
    );
  }
}

/// A card's own picture, at the thumb size the card language uses.
///
/// Backend-owned media: a service photo arrives as a `url`. The rounded clip
/// and the fixed square are the card's, the three-way precedence is
/// [AiUiImageView]'s.
class AiCardThumb extends StatelessWidget {
  /// Creates the thumbnail.
  const AiCardThumb({
    required this.source,
    required this.scope,
    required this.nodeType,
    required this.nodeId,
    super.key,
  });

  final AiUiImageSource? source;
  final AiUiRenderScope scope;
  final String nodeType;
  final String nodeId;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AiCardTokens.tileRadius),
    child: AiUiImageView(
      source: source,
      scope: scope,
      nodeType: nodeType,
      nodeId: nodeId,
      height: AiCardTokens.thumbHeight,
    ),
  );
}

/// A detail row inside its own bordered tile — Figma's `request_summary`
/// treatment, where each value sits on white inside a tinted container.
class AiDetailTile extends StatelessWidget {
  /// Creates the tile.
  const AiDetailTile({required this.item, super.key});

  final AiUiDetailItem item;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: context.appColors.surface,
      borderRadius: BorderRadius.circular(AiCardTokens.tileRadius),
    ),
    child: AiDetailRow(item: item, dense: true),
  );
}

/// An inline glyph-and-text row — the calendar and pin on an appointment, the
/// pin on a branch address.
class AiIconRow extends StatelessWidget {
  /// Creates the row.
  const AiIconRow({
    required this.icon,
    required this.text,
    this.emphasised = false,
    this.trailing,
    super.key,
  });

  final IconData icon;
  final String text;

  /// `true` uses the card's primary text colour, as Figma does on the
  /// appointment rows; `false` the secondary, as on a branch address.
  final bool emphasised;

  /// Placed at the end of the row — a branch's opening hours opposite its
  /// distance.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final color = emphasised ? colors.textPrimary : colors.textSecondary;

    return Row(
      spacing: AppSpacing.sm,
      children: [
        Icon(icon, size: AiCardTokens.rowGlyphSize, color: color),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (emphasised ? typography.smallNone : typography.tinyNone)
                .copyWith(color: color),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

/// A star and a locale-formatted rating value.
///
/// The design system has no rating widget — only `AiUiFormatters.rating`,
/// which returns the number as a string — so this is the one place the AI
/// layer draws stars.
class AiRatingRow extends StatelessWidget {
  /// Creates the row.
  const AiRatingRow({
    required this.value,
    required this.formatted,
    required this.outOfLabel,
    super.key,
  });

  /// 0–5, already clamped by the validator. Used only for the accessible
  /// label; the visual is a single star plus [formatted].
  final double value;

  /// The value as `AiUiFormatters.rating` rendered it.
  final String formatted;

  /// Client-supplied "out of 5" suffix for the accessible label.
  final String outOfLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Semantics(
      label: '$formatted $outOfLabel',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          Icon(
            Icons.star_rounded,
            size: AiCardTokens.starSize,
            color: colors.warning,
          ),
          Text(
            formatted,
            style: typography
                .semiBold(typography.tinyNone)
                .copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

/// A provider card's stats strip — small labels over emphasised values,
/// spread across the card.
class AiStatStrip extends StatelessWidget {
  /// Creates the strip.
  const AiStatStrip({required this.stats, super.key});

  final List<AiUiStat> stats;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.md,
      children: [
        for (final stat in stats)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  stat.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typography.tinyNone.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                SizedBox(height: AppSpacing.xs / 2),
                Text(
                  stat.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography
                      .semiBold(typography.smallNone)
                      .copyWith(color: colors.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// A tappable address row with a maps link — Figma's `maps-link`.
class AiMapsLinkRow extends StatelessWidget {
  /// Creates the row.
  const AiMapsLinkRow({
    required this.location,
    required this.linkLabel,
    required this.scope,
    super.key,
  });

  final AiUiLocationRef location;

  /// Client-supplied copy for the link line — the one string on this row the
  /// agent does not author, because it names a client capability.
  final String linkLabel;
  final AiUiRenderScope scope;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final onTap = scope.onTapFor(context, location.action);
    final radius = BorderRadius.circular(AiCardTokens.tileRadius);

    final content = Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: radius,
      ),
      child: Row(
        spacing: AppSpacing.sm,
        children: [
          Icon(
            Icons.location_on_outlined,
            size: AiCardTokens.discGlyphSize,
            color: AiUiTokens.accent(context),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  location.label ?? location.addressText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography.tinyNone.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (onTap != null) ...[
                  SizedBox(height: AppSpacing.xs / 2),
                  Text(
                    linkLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .semiBold(typography.smallNone)
                        .copyWith(color: AiUiTokens.accent(context)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return content;

    return Semantics(
      button: true,
      container: true,
      label: '$linkLabel: ${location.addressText}',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );
  }
}
