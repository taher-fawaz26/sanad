import 'package:design_system/src/components/internal/overlay_drag_handle.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/bottom_sheet_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Backdrops` (`40:9149`).
///
/// Renders a "back sheet" peek strip directly above a front sheet surface,
/// used to hint that a stacked sheet is behind the currently presented one.
///
/// Distinct from `SheetNavigation`'s own chrome (no peek) and [AppActionList]
/// (a plain scrimless row list).
///
/// **Documented gap:** the back-sheet peek in Figma is a flattened raster
/// image (not vector), so its exact fill/shadow cannot be extracted from
/// design tokens. This implementation reuses the front sheet's
/// `surfaceColor` and `topRadius` — an explicitly allowed reuse, not an
/// invented value. See `docs/DESIGN_SYSTEM.md` "Overlays" section.
class AppBackdrop extends StatelessWidget {
  const AppBackdrop({
    required this.child,
    super.key,
    this.title,
    this.showDragHandle = true,
  });

  final Widget child;
  final String? title;
  final bool showDragHandle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = BottomSheetTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spec.backdropPeekHorizontalInset,
          ),
          child: Container(
            height: spec.backdropPeekHeight,
            decoration: BoxDecoration(
              color: spec.surfaceColor,
              borderRadius: spec.topRadius,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: spec.surfaceColor,
            borderRadius: spec.topRadius,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showDragHandle) ...[
                SizedBox(height: spec.dragHandleTopPadding),
                OverlayDragHandle(
                  width: spec.dragHandleWidth,
                  height: spec.dragHandleHeight,
                  color: spec.dragHandleColor,
                ),
                SizedBox(height: AppSpacing.lg),
              ],
              if (title != null)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spec.horizontalPadding,
                  ),
                  child: Text(title!, style: spec.titleStyle),
                ),
              if (title != null) SizedBox(height: AppSpacing.lg),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  spec.horizontalPadding,
                  0,
                  spec.horizontalPadding,
                  AppSpacing.xxl,
                ),
                child: child,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
