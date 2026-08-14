import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Figma `Controls / Chips: Pill` visual style.
enum AppChipStyle {
  solid,
  outline,
}

/// Tonal chip preset — coverage tags, service tags (`365:14920`, `194:2647`).
enum AppChipTone {
  normal,
  softSuccess,
  softNeutral,
}

enum AppChipIconPosition {
  none,
  left,
  right,
}

enum AppChipSize {
  compact,
  expanded,
}

@immutable
class ChipSurfaceColors {
  const ChipSurfaceColors({
    required this.background,
    required this.foreground,
    required this.border,
  });

  final Color background;
  final Color foreground;
  final Color border;

  bool get hasBorder => border.a > 0;
}

/// Figma `Controls / Chips: Pill` (`40:7367`) token resolver.
abstract final class ChipTokens {
  ChipTokens._();

  static double minHeight(AppChipSize size) => switch (size) {
    AppChipSize.compact => AppDimension.fieldHeightMd - AppSpacing.sm,
    AppChipSize.expanded => AppDimension.fieldHeightMd,
  };

  static BorderRadius borderRadius(AppChipSize size) => BorderRadius.circular(
    size == AppChipSize.compact
        ? AppDimension.radiusPill
        : AppDimension.fieldHeightMd / 2,
  );

  static EdgeInsets padding({
    AppChipIconPosition iconPosition = AppChipIconPosition.none,
  }) {
    final vertical = AppSpacing.sm;
    final gap = AppSpacing.sm;
    return switch (iconPosition) {
      AppChipIconPosition.right => EdgeInsets.fromLTRB(
        AppSpacing.lg,
        vertical,
        AppSpacing.lg - gap / 2,
        vertical,
      ),
      AppChipIconPosition.left => EdgeInsets.fromLTRB(
        AppSpacing.lg - gap / 2,
        vertical,
        AppSpacing.lg,
        vertical,
      ),
      AppChipIconPosition.none => EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: vertical,
      ),
    };
  }

  static double iconGapSize() => AppSpacing.sm;

  static double? expandedWidthValue(AppChipSize size) =>
      size == AppChipSize.expanded ? AppDimension.contentMaxWidth : null;

  static TextStyle labelStyle(
    AppTypography typography,
    ChipSurfaceColors surface,
  ) {
    // Figma pill chips (`194:5964`) — 14 / Medium.
    return typography.smallNormal.copyWith(
      fontSize: 14.rfs,
      height: 16 / 14,
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: surface.foreground,
    );
  }

  static ChipSurfaceColors resolve({
    required AppChipStyle style,
    required bool selected,
    required AppColors colors,
    required Brightness brightness,
    AppChipTone tone = AppChipTone.normal,
  }) {
    final isDark = brightness == Brightness.dark;
    final clear = colors.palettes.white.withValues(alpha: 0);
    final main = colors.palettes.main;
    final sky = colors.palettes.sky;

    if (tone == AppChipTone.softSuccess) {
      return ChipSurfaceColors(
        background: isDark ? main.shade900 : main.shade50,
        foreground: isDark ? main.shade300 : main.shade700,
        border: clear,
      );
    }

    if (tone == AppChipTone.softNeutral) {
      return ChipSurfaceColors(
        background: isDark ? sky.shade800 : sky.shade100,
        foreground: colors.textPrimary,
        border: clear,
      );
    }

    if (style == AppChipStyle.outline) {
      if (selected) {
        // Figma coverage area tags (`194:5964`) — teal outline pill.
        return ChipSurfaceColors(
          background: clear,
          foreground: colors.primary,
          border: colors.primary,
        );
      }
      return ChipSurfaceColors(
        background: clear,
        foreground: colors.textPrimary,
        border: isDark ? colors.border : colors.controlFill,
      );
    }

    if (selected) {
      // Figma primary pill CTA chip (`347:14412`) — solid brand fill.
      return ChipSurfaceColors(
        background: colors.primary,
        foreground: colors.onPrimary,
        border: clear,
      );
    }

    return ChipSurfaceColors(
      background: isDark ? colors.surfaceVariant : colors.controlFill,
      foreground: colors.textPrimary,
      border: clear,
    );
  }

  static ChipThemeData chipTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final unselected = resolve(
      style: AppChipStyle.solid,
      selected: false,
      colors: colors,
      brightness: brightness,
    );
    final selectedSurface = resolve(
      style: AppChipStyle.solid,
      selected: true,
      colors: colors,
      brightness: brightness,
    );

    return ChipThemeData(
      backgroundColor: unselected.background,
      selectedColor: selectedSurface.background,
      disabledColor: colors.disabled,
      labelStyle: labelStyle(typography, unselected),
      secondaryLabelStyle: labelStyle(typography, selectedSurface),
      padding: padding(),
      shape: const StadiumBorder(),
      side: BorderSide.none,
      showCheckmark: false,
      elevation: 0,
      pressElevation: 0,
      brightness: brightness,
    );
  }
}
