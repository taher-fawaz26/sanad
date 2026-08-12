import 'package:design_system/design_system.dart'
    show AppSegmentedControl, AppTheme;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppSegmentedControl].
@immutable
class SegmentedControlStyleSpec {
  const SegmentedControlStyleSpec({
    required this.trackPadding,
    required this.trackDecoration,
    required this.itemHeight,
    required this.itemRadius,
    required this.selectedBackground,
    required this.selectedShadow,
    required this.selectedLabelStyle,
    required this.unselectedLabelStyle,
    required this.disabledLabelStyle,
  });

  final EdgeInsets trackPadding;
  final BoxDecoration trackDecoration;
  final double itemHeight;
  final BorderRadius itemRadius;
  final Color selectedBackground;
  final List<BoxShadow>? selectedShadow;
  final TextStyle selectedLabelStyle;
  final TextStyle unselectedLabelStyle;
  final TextStyle disabledLabelStyle;
}

/// Theme extension registered in [AppTheme] for Figma segmented controls.
@immutable
class AppSegmentedControlTheme
    extends ThemeExtension<AppSegmentedControlTheme> {
  const AppSegmentedControlTheme({required this.spec});

  /// Figma `Tab (5 Tabs)` (`5579:26572`, `5579:25923`) spec.
  final SegmentedControlStyleSpec spec;

  @override
  AppSegmentedControlTheme copyWith({SegmentedControlStyleSpec? spec}) {
    return AppSegmentedControlTheme(spec: spec ?? this.spec);
  }

  @override
  AppSegmentedControlTheme lerp(
    covariant AppSegmentedControlTheme? other,
    double t,
  ) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppSegmentedControlThemeX on BuildContext {
  AppSegmentedControlTheme get appSegmentedControlTheme =>
      Theme.of(this).extension<AppSegmentedControlTheme>()!;

  SegmentedControlStyleSpec segmentedControlSpec({bool showError = false}) {
    return SegmentedControlTokens.resolve(
      colors: appColors,
      typography: appTypography,
      brightness: Theme.of(this).brightness,
      showError: showError,
    );
  }
}

/// Figma `Tab (5 Tabs)` (`5579:26572`, `5579:25923`) token resolver.
abstract final class SegmentedControlTokens {
  SegmentedControlTokens._();

  static AppSegmentedControlTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppSegmentedControlTheme(
      spec: resolve(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static SegmentedControlStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
    bool showError = false,
  }) {
    final isDark = brightness == Brightness.dark;

    // Figma only specifies the light-mode surface; dark mode falls back to
    // the closest semantic tokens (no dark spec was provided).
    final trackBackground = isDark ? colors.surface : colors.white;
    final trackBorder = isDark ? colors.border : colors.slate200;
    final unselectedColor = isDark
        ? colors.textSecondary
        : colors.palettes.sky.shade700;

    final errorBorder = showError
        ? Border.all(
            color: colors.error,
            width: AppDimension.borderHairline * 2,
          )
        : null;

    final baseLabelStyle = typography.smallTight.copyWith(
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
    );

    return SegmentedControlStyleSpec(
      trackPadding: EdgeInsets.symmetric(
        horizontal: AppDimension.controlTrackPaddingHorizontal,
        vertical: AppSpacing.xs,
      ),
      trackDecoration: BoxDecoration(
        color: trackBackground,
        borderRadius: BorderRadius.circular(AppDimension.radiusLg),
        border: errorBorder ?? Border.all(color: trackBorder),
      ),
      itemHeight: AppDimension.fieldHeightMd,
      itemRadius: BorderRadius.circular(AppDimension.radiusTicketPill),
      selectedBackground: colors.primary,
      selectedShadow: null,
      selectedLabelStyle: baseLabelStyle.copyWith(color: colors.white),
      unselectedLabelStyle: baseLabelStyle.copyWith(color: unselectedColor),
      disabledLabelStyle: baseLabelStyle.copyWith(color: colors.textMuted),
    );
  }
}
