import 'package:design_system/design_system.dart'
    show AppSegmentedControl, AppTheme;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:design_system/src/utils/constants/app_shadows.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppSegmentedControl].
@immutable
class SegmentedControlStyleSpec {
  const SegmentedControlStyleSpec({
    required this.trackHeight,
    required this.trackPadding,
    required this.trackDecoration,
    required this.selectedSegmentRadius,
    required this.unselectedSegmentRadius,
    required this.selectedBackground,
    required this.unselectedBackground,
    required this.selectedShadow,
    required this.selectedLabelStyle,
    required this.unselectedLabelStyle,
    required this.segmentPadding,
  });

  final double trackHeight;
  final EdgeInsets trackPadding;
  final BoxDecoration trackDecoration;
  final BorderRadius selectedSegmentRadius;
  final BorderRadius unselectedSegmentRadius;
  final Color selectedBackground;
  final Color unselectedBackground;
  final List<BoxShadow>? selectedShadow;
  final TextStyle selectedLabelStyle;
  final TextStyle unselectedLabelStyle;
  final EdgeInsets segmentPadding;
}

/// Theme extension registered in [AppTheme] for Figma segmented controls.
@immutable
class AppSegmentedControlTheme
    extends ThemeExtension<AppSegmentedControlTheme> {
  const AppSegmentedControlTheme({required this.spec});

  /// Figma `Controls / Segmented Controls` (`40:7332`) spec (LTR default).
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
      textDirection: Directionality.of(this),
      showError: showError,
    );
  }
}

/// Figma `Controls / Segmented Controls` (`40:7332`) token resolver.
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
        textDirection: TextDirection.ltr,
      ),
    );
  }

  static SegmentedControlStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
    required TextDirection textDirection,
    bool showError = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final isRtl = textDirection == TextDirection.rtl;
    final trackInset = isRtl
        ? AppDimension.controlTrackInsetRtl
        : AppDimension.controlTrackInsetLtr;

    final errorBorder = showError
        ? Border.all(
            color: colors.error,
            width: AppDimension.borderHairline * 2,
          )
        : null;

    final labelSize = isDark ? 14.rfs : 12.rfs;

    return SegmentedControlStyleSpec(
      trackHeight: AppDimension.buttonMd,
      trackPadding: EdgeInsets.all(trackInset),
      trackDecoration: BoxDecoration(
        color: colors.controlFill,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        border: errorBorder,
      ),
      selectedSegmentRadius: BorderRadius.circular(
        AppDimension.radiusSegmentInner,
      ),
      unselectedSegmentRadius: BorderRadius.circular(AppDimension.radiusSm),
      selectedBackground: isDark ? colors.surfaceVariant : colors.surface,
      unselectedBackground: colors.palettes.white.withValues(alpha: 0),
      selectedShadow: AppShadows.small,
      selectedLabelStyle: typography.labelSmall.copyWith(
        fontSize: labelSize,
        height: 1,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colors.textPrimary,
      ),
      unselectedLabelStyle: typography.labelSmall.copyWith(
        fontSize: 12.rfs,
        height: 1,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        color: colors.textSecondary,
      ),
      segmentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
    );
  }
}
