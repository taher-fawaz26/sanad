import 'package:design_system/design_system.dart' show AppSearchField;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppSearchField].
@immutable
class SearchBarStyleSpec {
  const SearchBarStyleSpec({
    required this.height,
    required this.borderRadius,
    required this.backgroundColor,
    required this.iconColor,
    required this.hintStyle,
    required this.valueStyle,
    required this.cancelStyle,
    required this.cursorColor,
    required this.iconSize,
    required this.iconPadding,
    required this.iconGap,
    required this.cancelGap,
    required this.cancelAreaWidth,
  });

  final double height;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color iconColor;
  final TextStyle hintStyle;
  final TextStyle valueStyle;
  final TextStyle cancelStyle;
  final Color cursorColor;
  final double iconSize;
  final double iconPadding;
  final double iconGap;
  final double cancelGap;
  final double cancelAreaWidth;
}

/// Theme extension registered in [AppTheme] for Figma search bars.
@immutable
class AppSearchBarTheme extends ThemeExtension<AppSearchBarTheme> {
  const AppSearchBarTheme({required this.spec});

  /// Figma `Bars / Search Bars` (`40:6999`) spec for the active brightness.
  final SearchBarStyleSpec spec;

  @override
  AppSearchBarTheme copyWith({SearchBarStyleSpec? spec}) {
    return AppSearchBarTheme(spec: spec ?? this.spec);
  }

  @override
  AppSearchBarTheme lerp(covariant AppSearchBarTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppSearchBarThemeX on BuildContext {
  AppSearchBarTheme get appSearchBarTheme =>
      Theme.of(this).extension<AppSearchBarTheme>()!;
}

/// Figma `Bars / Search Bars` (`73:2915` / Default `40:7016`) token resolver.
abstract final class SearchBarTokens {
  SearchBarTokens._();

  static AppSearchBarTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppSearchBarTheme(
      spec: resolve(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static SearchBarStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;

    final baseStyle = typography.bodyMedium.copyWith(
      fontSize: 16.rfs,
      height: 1,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );

    return SearchBarStyleSpec(
      height: AppDimension.fieldHeightMd,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      backgroundColor: colors.controlFill,
      iconColor: isDark ? colors.textInverse : colors.textPrimary,
      hintStyle: baseStyle.copyWith(color: colors.textMuted),
      valueStyle: baseStyle.copyWith(color: colors.textPrimary),
      cancelStyle: baseStyle.copyWith(
        color: isDark ? colors.textMuted : colors.textPrimary,
      ),
      cursorColor: colors.primary,
      iconSize: AppDimension.iconCompact,
      iconPadding: AppSpacing.sm,
      iconGap: AppSpacing.md,
      cancelGap: AppSpacing.md,
      cancelAreaWidth: AppDimension.searchCancelAreaWidth,
    );
  }
}
