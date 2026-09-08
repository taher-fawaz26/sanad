import 'package:app_animations/app_animations.dart';
import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sanad_client/src/ui/glass/client_glass_surface.dart';
import 'package:sanad_client/src/ui/glass/client_glass_tokens.dart';

/// The three peer destinations of the Home shell.
enum AiHomeDestination {
  /// The AI chat itself.
  sanad,

  /// Structural placeholder — see `RequestsPage`.
  requests,

  /// Structural placeholder — see `MyLifePage`.
  myLife,
}

/// The three-segment nav pill — Figma `Frame1984079297` (`7827:30542`,
/// variants `Default`/`Variant2`/`Variant3`).
///
/// Not [AppSegmentedControl]: that component keeps every segment's label
/// visible and slides a highlight behind the selected one. This pill does
/// something else — the active segment expands into a labelled chip and the
/// other two collapse to bare icon buttons — which is a distinct interaction
/// Figma specifies for this exact control, not a variant `AppSegmentedControl`
/// exposes. Built from tokens/icons, not a new design system: one
/// feature-specific composition, not a competing generic component.
class AiHomeNavPill extends StatelessWidget {
  /// Creates the pill. [selected] is the active destination;
  /// [onSelected] fires when the user taps a different one.
  const AiHomeNavPill({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The active destination — the segment shown expanded with its label.
  final AiHomeDestination selected;

  /// Fired when a different segment is tapped. Navigation is the caller's
  /// job, matching every other affordance in this feature.
  final ValueChanged<AiHomeDestination> onSelected;

  @override
  Widget build(BuildContext context) => ClientGlassSurface(
    // Glass rather than the flat `surface` fill it used to carry. The pill
    // floats over the page's own gradient — and, on the landing state, over a
    // drifting glow — and a solid white panel hid exactly the thing that gives
    // the AI surface its identity. It still reads as a container grouping three
    // destinations, which is what the flat fill was there to achieve; it now
    // does it without blanking what is behind it.
    level: ClientGlassLevel.nav,
    borderRadius: AppRadius.circularXxl,
    padding: EdgeInsets.all(AppSpacing.xs),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final destination in AiHomeDestination.values)
          _Segment(
            destination: destination,
            selected: destination == selected,
            onTap: () => onSelected(destination),
          ),
      ],
    ),
  );
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final AiHomeDestination destination;
  final bool selected;
  final VoidCallback onTap;

  static const _svgAsset = <AiHomeDestination, String>{
    AiHomeDestination.sanad: AppSvgs.aiChatNavMark,
    AiHomeDestination.requests: AppSvgs.aiChatNavPaper,
    AiHomeDestination.myLife: AppSvgs.aiChatNavFolder,
  };

  static const _labelKey = <AiHomeDestination, String>{
    AiHomeDestination.sanad: 'ai_chat.nav_sanad',
    AiHomeDestination.requests: 'ai_chat.nav_requests',
    AiHomeDestination.myLife: 'ai_chat.nav_my_life',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final label = _labelKey[destination]!.tr();

    // Sanad's own mark keeps its brand colors baked in, matching Figma
    // exactly, even when inactive — the other two are single-color line
    // icons and switch between the muted/active tint via `colorFilter`.
    final icon = destination == AiHomeDestination.sanad
        ? SvgPicture.asset(
            _svgAsset[destination]!,
            package: AppAssets.package,
            width: 19,
            height: 19,
          )
        : SvgPicture.asset(
            _svgAsset[destination]!,
            package: AppAssets.package,
            width: 20,
            height: 20,
            colorFilter: ColorFilter.mode(
              selected ? colors.primary : colors.textSecondary,
              BlendMode.srcIn,
            ),
          );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.circularXxl,
          child: AnimatedContainer(
            duration: AppMotionDuration.quick,
            curve: AppMotionCurve.standard,
            height: 44,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: selected ? AppSpacing.md : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              // Figma fills the active segment with `#F9F9FA` — a neutral
              // grey against the pill's white, which the theme carries as
              // `background` (`DarkPalette.shade50`). Not `surfaceVariant`:
              // that is `MainPalette.shade50` (`#E5FEF7`), a mint green that
              // turned the selected segment into a coloured chip Figma does
              // not have.
              color: selected ? colors.background : Colors.transparent,
              borderRadius: AppRadius.circularXxl,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.xs,
              children: [
                icon,
                // The collapsed icon-only segments carry the label only in
                // semantics (above); visually it appears only once selected,
                // which is the interaction Figma specifies for this control.
                AnimatedSize(
                  duration: AppMotionDuration.quick,
                  curve: AppMotionCurve.standard,
                  child: selected
                      ? ExcludeSemantics(
                          child: ConstrainedBox(
                            // A raw i18n key (this repo's widget-test
                            // convention) or a large accessibility text
                            // scale can both demand far more width than any
                            // real translated label needs — capped and
                            // ellipsized so either shrinks the pill's own
                            // label instead of overflowing the whole header.
                            constraints: const BoxConstraints(maxWidth: 90),
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.appTypography.regularNormal
                                  .copyWith(
                                    color: colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
