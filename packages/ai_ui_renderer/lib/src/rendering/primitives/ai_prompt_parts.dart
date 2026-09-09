import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/src/rendering/ai_card_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_render_scope.dart';
import 'package:ai_ui_renderer/src/rendering/ai_ui_tokens.dart';
import 'package:ai_ui_renderer/src/rendering/primitives/ai_ui_image_view.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The pieces the prompt cards are assembled from — `media_request`,
/// `permission_request`, `location_picker`, `location_confirm`.
///
/// Figma draws these four as bottom sheets. As AI-rendered nodes they render
/// inline in the assistant bubble, so the sheet's grabber and home indicator
/// have no equivalent — everything inside the sheet's content area does.

/// A prompt's headline and supporting paragraph — Figma's `header-text-group`.
class AiPromptHeader extends StatelessWidget {
  /// Creates the block.
  const AiPromptHeader({required this.title, this.body, super.key});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: AppSpacing.sm,
      children: [
        Text(
          title,
          style: typography
              .bold(typography.title3)
              .copyWith(color: colors.textPrimary, letterSpacing: 0),
        ),
        if (body != null)
          Text(
            body!,
            style: typography.regularNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
      ],
    );
  }
}

/// A tappable option row — Figma's `option-card`.
///
/// Not `SheetActionRow` from `shared_ui`: that draws a tinted icon-and-label
/// row for a sheet's destructive/neutral actions, with no border, no subtitle
/// slot and its own colour contract. Figma's option card is a bordered white
/// row at an 18dp radius that may carry a second line, and it is the shape
/// three of the four prompts are built from.
class AiOptionRow extends StatelessWidget {
  /// Creates the row.
  const AiOptionRow({
    required this.label,
    required this.onTap,
    this.icon,
    this.subtitle,
    this.accented = false,
    this.selected = false,
    super.key,
  });

  final String label;

  /// A second line under [label] — a saved place's address.
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onTap;

  /// Draws the label in the AI accent — Figma's "Use current location".
  final bool accented;

  /// Draws the accent border, for a row the user has chosen.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final accent = AiUiTokens.accent(context);
    final radius = BorderRadius.circular(AiCardTokens.optionRadius);

    final content = Container(
      padding: EdgeInsetsDirectional.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(
          color: selected ? accent : colors.border,
          width: selected
              ? AiCardTokens.emphasisBorderWidth
              : AppDimension.borderHairline,
        ),
      ),
      child: Row(
        spacing: AppSpacing.md,
        children: [
          if (icon != null)
            Icon(
              icon,
              size: AppDimension.iconMd,
              color: accented ? accent : colors.textPrimary,
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: accented
                      ? typography
                            .semiBold(typography.regularNone)
                            .copyWith(color: accent)
                      : typography.regularNone.copyWith(
                          color: colors.textPrimary,
                        ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: AppSpacing.xs),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.tinyNone.copyWith(
                      color: colors.textSecondary,
                    ),
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
      selected: selected,
      label: subtitle == null ? label : '$label, $subtitle',
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(onTap: onTap, borderRadius: radius, child: content),
      ),
    );
  }
}

/// The map illustration above a location prompt — Figma's
/// `illustration-container`.
///
/// Asset-backed rather than a live map: `packages/maps` would drag Google Maps
/// into every consumer of this renderer, including the design catalog and the
/// widget tests. An app that can draw a real map registers its own renderer
/// over the owning node type — which is what `AiUiRendererRegistry.register`
/// exists for.
class AiMapPreview extends StatelessWidget {
  /// Creates the preview.
  const AiMapPreview({
    required this.source,
    required this.scope,
    required this.nodeType,
    required this.nodeId,
    super.key,
  });

  /// The node's canonical image object. A backend that has a real static map
  /// for this place sends a `url`; otherwise the client's own
  /// `ai_map_preview` illustration is the sensible `assetId`. Either way the
  /// precedence and the failure behaviour are [AiUiImageView]'s, not this
  /// widget's.
  final AiUiImageSource? source;
  final AiUiRenderScope scope;
  final String nodeType;
  final String nodeId;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AiCardTokens.optionRadius);

    return Container(
      height: AiCardTokens.mapPreviewHeight,
      decoration: BoxDecoration(
        color: context.appColors.controlFill,
        borderRadius: radius,
      ),
      clipBehavior: Clip.antiAlias,
      // Figma draws the map at 60% so it reads as an illustration rather than
      // a live map the user could pan. The tinted block underneath is the
      // no-image state.
      child: Opacity(
        opacity: AiCardTokens.mapPreviewOpacity,
        child: AiUiImageView(
          source: source,
          scope: scope,
          nodeType: nodeType,
          nodeId: nodeId,
          height: AiCardTokens.mapPreviewHeight,
          fallback: const SizedBox.shrink(),
        ),
      ),
    );
  }
}

/// A grid of selectable slots — Figma's `grid-layout`, two per row.
///
/// `AppChip` is the design system's selectable pill and is used elsewhere for
/// exactly this, but it sizes itself to its label; Figma's slots are
/// equal-width across the row so the grid reads as a table of times. Each cell
/// therefore draws the chip's treatment at a fixed width.
class AiSlotGrid extends StatelessWidget {
  /// Creates the grid.
  const AiSlotGrid({
    required this.slots,
    required this.selectedId,
    required this.onSelected,
    super.key,
  });

  final List<AiUiTimeSlot> slots;
  final String? selectedId;
  final ValueChanged<AiUiTimeSlot> onSelected;

  @override
  Widget build(BuildContext context) {
    final rows = <List<AiUiTimeSlot>>[];
    for (var i = 0; i < slots.length; i += AiCardTokens.slotColumns) {
      rows.add(
        slots.sublist(
          i,
          (i + AiCardTokens.slotColumns).clamp(0, slots.length),
        ),
      );
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
              for (final slot in row)
                Expanded(
                  child: _Slot(
                    slot: slot,
                    selected: slot.id == selectedId,
                    onTap: slot.enabled ? () => onSelected(slot) : null,
                  ),
                ),
              // Keeps the last row's single slot half-width rather than
              // stretching it across the card, so the grid stays a grid.
              for (var i = row.length; i < AiCardTokens.slotColumns; i++)
                const Expanded(child: SizedBox.shrink()),
            ],
          ),
      ],
    );
  }
}

class _Slot extends StatelessWidget {
  const _Slot({required this.slot, required this.selected, this.onTap});

  final AiUiTimeSlot slot;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final accent = AiUiTokens.accent(context);
    final radius = BorderRadius.circular(AppDimension.radiusPill);

    final enabled = onTap != null;
    final foreground = switch ((selected, enabled)) {
      (true, _) => colors.palettes.dark.shade50,
      (false, true) => colors.textSecondary,
      (false, false) => colors.textDisabled,
    };

    return Semantics(
      button: enabled,
      enabled: enabled,
      selected: selected,
      label: slot.label,
      excludeSemantics: true,
      child: Material(
        color: selected ? accent : Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Container(
            height: AiCardTokens.slotHeight,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: selected ? null : Border.all(color: colors.border),
            ),
            child: Text(
              slot.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (selected
                          ? typography.semiBold(typography.tinyNone)
                          : typography.medium(typography.tinyNone))
                      .copyWith(color: foreground),
            ),
          ),
        ),
      ),
    );
  }
}
