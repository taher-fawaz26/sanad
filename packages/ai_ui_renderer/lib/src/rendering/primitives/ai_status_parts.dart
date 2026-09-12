import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_formatters.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_ui_image_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The pieces the offer, timeline, code and confirmation cards are assembled
/// from.
///
/// Companion to `ai_card_content.dart`, which holds the parts the original
/// card set shares. Split by *when they arrived* rather than by kind, because
/// that file is already the length where finding anything means scrolling —
/// and because everything here has to work for both the compact and expanded
/// readings of the same node.
///
/// Nothing in this file positions anything with `left`/`right`. Every row is
/// a `Row` (which mirrors), every inset is `EdgeInsetsDirectional`, and the
/// one place a direction is forced — a verification code — forces it on a
/// value that is left-to-right in every language.

/// A provider's portrait, round, with the person glyph as its no-image state.
///
/// Shared by `provider_card` and by the provider row a `booking_summary`
/// carries, so a booking and the offer it came from show the same face at the
/// same size.
class AiProviderAvatar extends StatelessWidget {
  /// Creates the avatar.
  const AiProviderAvatar({
    required this.source,
    required this.scope,
    required this.nodeType,
    required this.nodeId,
    this.size,
    super.key,
  });

  /// The canonical `{url?, assetId?}` object. A portrait is backend-owned
  /// media, so in practice it arrives as a URL; the precedence is
  /// [AiUiImageView]'s either way.
  final AiUiImageSource? source;
  final AiUiRenderScope scope;
  final String nodeType;
  final String nodeId;

  /// Defaults to the card language's avatar size.
  final double? size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final diameter = size ?? AiCardTokens.avatarSize;

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        color: colors.controlFill,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: AiUiImageView(
        source: source,
        scope: scope,
        nodeType: nodeType,
        nodeId: nodeId,
        width: diameter,
        height: diameter,
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

/// A provider's name with the verification tick after it.
///
/// The tick carries its own `Semantics` label rather than riding on the name's
/// string: a glyph with no text is silent to a screen reader, and "verified"
/// is precisely the fact the mark exists to convey.
class AiVerifiedName extends StatelessWidget {
  /// Creates the name row.
  const AiVerifiedName({
    required this.name,
    required this.verified,
    required this.verifiedLabel,
    this.style,
    super.key,
  });

  final String name;
  final bool verified;

  /// Already-localized client copy, from `AiUiStrings.verifiedLabel`.
  final String verifiedLabel;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final resolved =
        style ??
        typography
            .bold(typography.regularNone)
            .copyWith(color: context.appColors.textPrimary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: resolved,
          ),
        ),
        if (verified) ...[
          SizedBox(width: AppSpacing.xs),
          Semantics(
            label: verifiedLabel,
            child: Icon(
              Icons.verified_rounded,
              size: AiCardTokens.verifiedGlyphSize,
              color: AiUiTokens.accent(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// The disclosure control on an expandable card — Figma's chevron.
///
/// A rotating chevron rather than two glyphs, so the control reads as one
/// affordance changing state. It carries the expanded flag into `Semantics` so
/// a screen reader announces "expanded"/"collapsed" rather than only a label.
class AiDisclosureButton extends StatelessWidget {
  /// Creates the control.
  const AiDisclosureButton({
    required this.expanded,
    required this.onTap,
    required this.label,
    super.key,
  });

  final bool expanded;
  final VoidCallback onTap;

  /// Already-localized client copy — "Show more" / "Show less".
  final String label;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    expanded: expanded,
    label: label,
    child: InkResponse(
      onTap: onTap,
      radius: AiCardTokens.disclosureSize / 2,
      child: SizedBox(
        width: AiCardTokens.disclosureSize,
        height: AiCardTokens.disclosureSize,
        child: Center(
          child: Icon(
            // Vertical, so it never needs mirroring: the card expands
            // downwards in both directions.
            expanded
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: AppDimension.iconMd,
            color: context.appColors.textSecondary,
          ),
        ),
      ),
    ),
  );
}

/// A read-only strip of short labels — a provider's services.
///
/// `Wrap` rather than a scrolling row: a horizontal scroller inside a chat
/// bubble competes with the message list's own gesture, and the validator
/// already caps how many of these there can be.
class AiTagChips extends StatelessWidget {
  /// Creates the strip.
  const AiTagChips({required this.labels, super.key});

  final List<String> labels;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
    children: [
      for (final label in labels)
        // No `onTap`: choosing a service belongs to the conversation, and the
        // protocol has no way to attach an action to one of these.
        AppChip(label: label, style: AppChipStyle.outline),
    ],
  );
}

/// A row of square pictures — a provider's work samples, a request's
/// attachments.
///
/// Each cell is an `Expanded` square rather than a fixed width, so three
/// photos fill the card at any width and two do not leave a gap the eye reads
/// as a missing third.
class AiPhotoStrip extends StatelessWidget {
  /// Creates the strip.
  const AiPhotoStrip({
    required this.photos,
    required this.scope,
    required this.nodeType,
    required this.nodeId,
    super.key,
  });

  /// Already validated: an entry with no usable url or assetId was dropped.
  final List<AiUiImageSource> photos;
  final AiUiRenderScope scope;
  final String nodeType;
  final String nodeId;

  /// How many fit across before the strip wraps to a second line.
  static const int columns = 3;

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty) return const SizedBox.shrink();

    final rows = <List<AiUiImageSource>>[];
    for (var i = 0; i < photos.length; i += columns) {
      rows.add(photos.sublist(i, (i + columns).clamp(0, photos.length)));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        for (final row in rows)
          Row(
            spacing: AppSpacing.sm,
            children: [
              for (final photo in row)
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      AiCardTokens.tileRadius,
                    ),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AiUiImageView(
                        source: photo,
                        scope: scope,
                        nodeType: nodeType,
                        nodeId: nodeId,
                      ),
                    ),
                  ),
                ),
              // Keeps a trailing partial row's cells the same size as a full
              // row's, instead of stretching two photos across the card.
              for (var i = row.length; i < columns; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
      ],
    );
  }
}

/// A label-and-value pair stacked, label above value.
///
/// Figma's confirmation layout, against `AiDetailRow`'s label-start /
/// value-end one. The distinction is real rather than cosmetic: a summary the
/// user is *checking* reads as a table of comparisons, where a booking that
/// has already happened reads as a set of facts, and a long address wrapping
/// under its own label is what the second one needs.
class AiStackedDetailRow extends StatelessWidget {
  /// Creates the pair.
  const AiStackedDetailRow({required this.item, super.key});

  final AiUiDetailItem item;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final valueColor = item.valueTone == AiUiTone.neutral
        ? colors.textPrimary
        : AiUiTokens.toneColor(context, item.valueTone);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          item.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.tinyNone.copyWith(color: colors.textMuted),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          // A booking reference is exactly the value this exists for: without
          // the isolate, "#SND-8829-AQ" renders its hash at the far end under
          // Arabic (the SAN-770 bug class).
          item.isLtrValue ? item.value.ltrIsolated : item.value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: typography
              .semiBold(typography.smallNone)
              .copyWith(color: valueColor),
        ),
      ],
    );
  }
}

/// A run of [AiStackedDetailRow]s.
class AiStackedDetails extends StatelessWidget {
  /// Creates the block.
  const AiStackedDetails({required this.items, super.key});

  final List<AiUiDetailItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.lg,
    children: [
      for (final item in items) AiStackedDetailRow(item: item),
    ],
  );
}

/// The thing a `confirm_prompt` is deciding about, in its own tile.
///
/// Bordered and filled so the question above it cannot be misread as being
/// about the conversation in general: the user is cancelling *this* booking.
class AiSubjectTile extends StatelessWidget {
  /// Creates the tile.
  const AiSubjectTile({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AiCardTokens.tileRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: typography
                .bold(typography.smallNone)
                .copyWith(color: colors.textPrimary),
          ),
          if (subtitle != null) ...[
            SizedBox(height: AppSpacing.xs),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: typography.tinyNone.copyWith(color: colors.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

/// A small tinted pill above a card's headline — "Finding providers…",
/// "verification code".
class AiStatusPill extends StatelessWidget {
  /// Creates the pill.
  const AiStatusPill({
    required this.label,
    this.icon,
    this.tone = AiUiTone.primary,
    this.bordered = false,
    this.dot = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final AiUiTone tone;

  /// Figma's `verification code` pill, which is outlined on white rather than
  /// filled — the same shape reading as a field label instead of a status.
  final bool bordered;

  /// Leads with a filled disc instead of a glyph — Figma's `Booking
  /// Cancelled` / `Provider is late` status pill on the notice cards.
  ///
  /// A third leading treatment on the same pill rather than a second pill
  /// component: the shape, the padding and the type are identical, and only
  /// what sits before the label differs.
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final foreground = bordered
        ? colors.textSecondary
        : AiUiTokens.onToneContainer(context, tone);

    return Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: bordered
            ? Colors.transparent
            : AiUiTokens.toneContainer(context, tone),
        borderRadius: BorderRadius.circular(AppDimension.radiusPill),
        border: bordered ? Border.all(color: colors.border) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: AppSpacing.xs,
        children: [
          if (dot)
            Container(
              width: AiCardTokens.statusDotSize,
              height: AiCardTokens.statusDotSize,
              decoration: BoxDecoration(
                color: foreground,
                shape: BoxShape.circle,
              ),
            )
          else if (icon != null)
            Icon(icon, size: AiCardTokens.verifiedGlyphSize, color: foreground),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: typography
                  .semiBold(typography.tinyNone)
                  .copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }
}

/// The ordered steps of a `service_timeline`.
///
/// The rail is drawn as part of each row rather than as one background line,
/// so a step's connector is exactly as tall as that step — which is what lets
/// a two-line description and a one-line one sit in the same list without the
/// rail drifting away from the markers.
class AiTimeline extends StatelessWidget {
  /// Creates the timeline.
  const AiTimeline({required this.items, super.key});

  /// Already validated and in the agent's own order.
  final List<AiUiTimelineItem> items;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final (index, item) in items.indexed)
        _TimelineRow(item: item, isLast: index == items.length - 1),
    ],
  );
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({required this.item, required this.isLast});

  final AiUiTimelineItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final at = item.at;

    return Semantics(
      container: true,
      selected: item.isCurrent,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: AppSpacing.md,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _TimelineMarker(state: item.state),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: AiCardTokens.timelineConnectorWidth,
                      constraints: BoxConstraints(
                        minHeight: AiCardTokens.timelineConnectorMinHeight,
                      ),
                      color: colors.border,
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  bottom: isLast ? 0 : AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                (item.isCurrent
                                        ? typography.bold(
                                            typography.smallNone,
                                          )
                                        : typography.semiBold(
                                            typography.smallNone,
                                          ))
                                    .copyWith(
                                      color:
                                          item.state ==
                                              AiUiTimelineState.pending
                                          ? colors.textSecondary
                                          : colors.textPrimary,
                                    ),
                          ),
                        ),
                        if (at != null) ...[
                          SizedBox(width: AppSpacing.sm),
                          Text(
                            AiUiFormatters.dateTime(context, at),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            // A date and time is one left-to-right run in both
                            // languages, exactly as a time slot's label is.
                            textDirection: AiUiFormatters.valueDirection(
                              AiUiFormatters.dateTime(context, at),
                            ),
                            style: typography.tinyNone.copyWith(
                              color: colors.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.description != null) ...[
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        item.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: typography.tinyNone.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// One step's rail marker. The glyph and the fill both follow the state, so a
/// cancelled step never shows a tick.
class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({required this.state});

  final AiUiTimelineState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = AiUiTokens.accent(context);

    final (background, foreground, border, glyph) = switch (state) {
      AiUiTimelineState.completed => (
        accent,
        colors.palettes.dark.shade50,
        accent,
        Icons.check_rounded,
      ),
      AiUiTimelineState.active => (
        Colors.transparent,
        accent,
        accent,
        Icons.radio_button_checked_rounded,
      ),
      AiUiTimelineState.cancelled => (
        Colors.transparent,
        colors.error,
        colors.error,
        Icons.close_rounded,
      ),
      AiUiTimelineState.pending => (
        Colors.transparent,
        colors.textMuted,
        colors.border,
        Icons.circle_outlined,
      ),
    };

    return Container(
      width: AiCardTokens.timelineMarkerSize,
      height: AiCardTokens.timelineMarkerSize,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Center(
        child: Icon(
          glyph,
          size: AiCardTokens.timelineGlyphSize,
          color: foreground,
        ),
      ),
    );
  }
}

/// A verification code, one character per box.
///
/// Forced left-to-right as a *row*, not per box: a code is an ordered sequence
/// of characters, and mirroring the row under Arabic would read it back to
/// front. This is the same reasoning `AppOtpField` applies to its digits, and
/// the reason `ui.md` allows forcing direction for intrinsically-LTR content.
class AiCodeRow extends StatelessWidget {
  /// Creates the row.
  const AiCodeRow({required this.code, super.key});

  final String code;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final characters = code.split('');

    return Semantics(
      // Announced as one value rather than as a run of single characters, and
      // read out with the digits separated so "65066" is not spoken as
      // "sixty-five thousand and sixty-six".
      label: characters.join(' '),
      excludeSemantics: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        // Boxes are a fixed size, and the protocol allows a code of up to
        // `maxVerificationCodeLength` characters — so past four or five they
        // stop fitting the width a card has inside a chat bubble and the row
        // overflows. `scaleDown` keeps the design at its intended size whenever
        // there is room and shrinks only a code that genuinely cannot fit,
        // which is the same trade `_HeroFitted` makes on the chat landing.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: AppSpacing.sm,
            children: [
              for (final character in characters)
                Container(
                  width: AiCardTokens.codeBoxSize,
                  height: AiCardTokens.codeBoxSize,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(
                      AiCardTokens.codeBoxRadius,
                    ),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    character,
                    style: typography
                        .bold(typography.title3)
                        .copyWith(color: colors.textPrimary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A tappable star row — the rating half of a `review_request`.
///
/// The stars are the control, so each one is its own button with its own
/// semantics ("3 stars") rather than one widget the user drags across: a drag
/// target inside a scrolling message list fights the list's own gesture.
class AiStarRating extends StatelessWidget {
  /// Creates the row.
  const AiStarRating({
    required this.value,
    required this.max,
    required this.onChanged,
    required this.starsLabel,
    super.key,
  });

  /// The chosen rating, or `null` for none yet.
  final int? value;

  /// How many stars the card offers.
  final int max;

  /// `null` leaves the row read-only — what a submitted card shows.
  final ValueChanged<int>? onChanged;

  /// Already-localized client copy, from `AiUiStrings.ratingStarsLabel`.
  final String starsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chosen = value ?? 0;
    final enabled = onChanged != null;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSpacing.sm,
      children: [
        for (var star = 1; star <= max; star++)
          Semantics(
            button: true,
            enabled: enabled,
            selected: star <= chosen,
            label: '$star $starsLabel',
            excludeSemantics: true,
            child: InkResponse(
              onTap: enabled ? () => onChanged!(star) : null,
              radius: AiCardTokens.ratingStarSize / 2,
              child: Icon(
                star <= chosen
                    ? Icons.star_rounded
                    : Icons.star_outline_rounded,
                size: AiCardTokens.ratingStarSize,
                color: star <= chosen ? colors.warning : colors.border,
              ),
            ),
          ),
      ],
    );
  }
}
