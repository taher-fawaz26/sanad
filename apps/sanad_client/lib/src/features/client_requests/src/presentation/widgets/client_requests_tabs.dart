import 'package:app_animations/app_animations.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_requests_tab.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/client_requests_tokens.dart';

/// The three segments across the top of Requests — Figma `StatusPills`
/// (`8385:4377`).
///
/// Deliberately **not** the horizontally-scrolling `AppChip` row this screen
/// used to carry, and not [AppSegmentedControl] either. Figma draws three
/// equal-width pills that between them span the content column exactly: they
/// have to divide the available width, which a scrolling list of
/// intrinsically-sized chips cannot do and a segmented control's shared track
/// draws differently (one recessed track, not three separate pills).
class ClientRequestsTabs extends StatelessWidget {
  /// Creates the tab row.
  const ClientRequestsTabs({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// The active segment.
  final ClientRequestsTab selected;

  /// Fired when a different segment is tapped.
  final ValueChanged<ClientRequestsTab> onSelected;

  @override
  Widget build(BuildContext context) => Padding(
    // Figma `StatusPills`: 20/8.
    padding: EdgeInsetsDirectional.symmetric(
      horizontal: AppSpacing.xl,
      vertical: AppSpacing.sm,
    ),
    child: Row(
      spacing: AppSpacing.sm,
      children: [
        for (final tab in ClientRequestsTab.values)
          Expanded(
            child: _TabPill(
              label: tab.labelKey.tr(),
              selected: tab == selected,
              onTap: () => onSelected(tab),
            ),
          ),
      ],
    ),
  );
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final radius = BorderRadius.circular(ClientRequestsTokens.tabRadius);

    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          // `TweenAnimationBuilder<Decoration>` rather than
          // `AnimatedContainer`, specifically so the decorated box stays an
          // `Ink` (needed for the tap ripple above to paint layered *under*
          // the fill/border rather than as a separate overlay on top of it —
          // an `AnimatedContainer` can't do that, only `Ink` can) while still
          // cross-fading color/border on a `selected` toggle instead of
          // snapping.
          child: TweenAnimationBuilder<Decoration>(
            tween: DecorationTween(
              end: BoxDecoration(
                color: selected
                    ? ClientRequestsTokens.tabSelectedFill
                    : colors.surface,
                borderRadius: radius,
                border: Border.all(
                  color: selected
                      // `#26A68C` — `main/600` exactly.
                      ? colors.palettes.main.shade600
                      : ClientRequestsTokens.tabBorder,
                  width: AppDimension.borderHairline,
                ),
              ),
            ),
            duration: AppMotionDuration.fast,
            curve: AppMotionCurve.standard,
            builder: (context, decoration, child) => Ink(
              height: ClientRequestsTokens.tabHeight,
              decoration: decoration,
              child: child,
            ),
            child: Center(
              child: Padding(
                // Figma px-14. The label ellipsizes rather than pushing the
                // pill wider: three equal columns at 360dp leave ~105dp each,
                // and a long translation must not overflow the row.
                padding: EdgeInsetsDirectional.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: AnimatedDefaultTextStyle(
                  duration: AppMotionDuration.fast,
                  curve: AppMotionCurve.standard,
                  style: typography.smallNormal.copyWith(
                    fontSize: 13.rfs,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    color: selected
                        ? colors.onPrimary
                        : ClientRequestsTokens.tabLabel,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
