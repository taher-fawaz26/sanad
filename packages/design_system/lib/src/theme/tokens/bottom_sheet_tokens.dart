import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/overlay_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for bottom sheets and backdrops.
///
/// Note: [AppBottomSheet] has **no** dimming barrier (Figma `40:9140`).
/// Scrim lives on [AppActionSheet] / [OverlayTokens.scrimColor] only.
@immutable
class BottomSheetStyleSpec {
  const BottomSheetStyleSpec({
    required this.topRadius,
    required this.dragHandleWidth,
    required this.dragHandleHeight,
    required this.dragHandleTopPadding,
    required this.dragHandleColor,
    required this.surfaceColor,
    required this.horizontalPadding,
    required this.titleStyle,
    required this.bodyStyle,
    required this.backdropPeekHeight,
    required this.backdropPeekHorizontalInset,
  });

  final BorderRadius topRadius;
  final double dragHandleWidth;
  final double dragHandleHeight;
  final double dragHandleTopPadding;
  final Color dragHandleColor;
  final Color surfaceColor;
  final double horizontalPadding;
  final TextStyle titleStyle;
  final TextStyle bodyStyle;

  /// Height of the `AppBackdrop` back-sheet peek strip
  /// (Figma `Views / Backdrops`, `40:9149`).
  final double backdropPeekHeight;

  /// Horizontal inset of the back-sheet peek strip from the front sheet's
  /// edges (Figma `Views / Backdrops`, `40:9149`).
  final double backdropPeekHorizontalInset;
}

/// Figma `Views / Bottom Sheets` (`40:9140`) and `Backdrops` (`40:9149`).
abstract final class BottomSheetTokens {
  BottomSheetTokens._();

  static const double topRadius = 16;
  static const double dragHandleWidth = 48;
  static const double dragHandleHeight = 5;
  static const double dragHandleTopPadding = 8;
  static const double horizontalPadding = 24;

  /// Vertical gap between major sections in confirmation sheets
  /// (Figma `Sheet Content` `1526:13048`).
  static const double confirmationSectionGap = 24;

  /// Gap inside the text group and between stacked action buttons.
  static const double confirmationInnerGap = 12;

  /// Extra top inset below the drag handle before confirmation title text.
  /// Combined with [AppBottomSheet]'s post-handle gap (`AppSpacing.lg`) this
  /// totals [confirmationSectionGap].
  static const double confirmationContentTopGap = 8;

  /// Default height fraction for [showAppModalSheet] — the sheet occupies
  /// this proportion of the screen height.
  static const double modalHeightFraction = 0.92;

  // Views/Backdrops (`40:9149`) — back-sheet peek strip visible above the
  // front sheet. The peek itself is a flattened raster image in Figma (not
  // vector), so its exact fill/shadow cannot be extracted from tokens; this
  // reuses the front sheet's `surfaceColor`/`topRadius` (documented, allowed
  // reuse — not invention). See docs/DESIGN_SYSTEM.md "Overlays" section.
  static const double backdropPeekHeight = 10;
  static const double backdropPeekHorizontalInset = 16;

  static BottomSheetStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    return BottomSheetStyleSpec(
      topRadius: BorderRadius.vertical(
        top: Radius.circular(responsiveDimension(topRadius)),
      ),
      dragHandleWidth: responsiveDimension(dragHandleWidth),
      dragHandleHeight: responsiveDimension(dragHandleHeight),
      dragHandleTopPadding: responsiveDimension(dragHandleTopPadding),
      dragHandleColor: isDark ? OverlayTokens.ink600 : OverlayTokens.chromeBase,
      surfaceColor: isDark ? OverlayTokens.ink800 : colors.white,
      horizontalPadding: responsiveDimension(horizontalPadding),
      titleStyle: typography.title3.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.textPrimary,
      ),
      bodyStyle: typography.regularNormal.copyWith(
        color: colors.textSecondary,
      ),
      backdropPeekHeight: responsiveDimension(backdropPeekHeight),
      backdropPeekHorizontalInset: responsiveDimension(
        backdropPeekHorizontalInset,
      ),
    );
  }

  static BottomSheetThemeData bottomSheetTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final spec = resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return BottomSheetThemeData(
      backgroundColor: spec.surfaceColor,
      modalBackgroundColor: spec.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: spec.topRadius),
      dragHandleColor: spec.dragHandleColor,
      showDragHandle: true,
      elevation: 0,
    );
  }
}
