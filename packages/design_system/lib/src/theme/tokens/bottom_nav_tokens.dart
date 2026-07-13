import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:design_system/src/utils/constants/app_shadows.dart';
import 'package:flutter/material.dart';

@immutable
class AppBottomNavItem {
  const AppBottomNavItem({
    required this.iconAsset,
    required this.label,
  });

  /// SVG asset path — prefer [AppSvgs.navHome] and siblings.
  final String iconAsset;
  final String label;
}

@immutable
class BottomNavItemStyleSpec {
  const BottomNavItemStyleSpec({
    required this.selectedLabelStyle,
    required this.unselectedLabelStyle,
    required this.selectedIconColor,
    required this.unselectedIconColor,
    required this.itemBackgroundColor,
  });

  final TextStyle selectedLabelStyle;
  final TextStyle unselectedLabelStyle;
  final Color selectedIconColor;
  final Color unselectedIconColor;
  final Color itemBackgroundColor;
}

@immutable
class BottomNavStyleSpec {
  const BottomNavStyleSpec({
    required this.height,
    required this.backgroundColor,
    required this.shadow,
    required this.iconSize,
    required this.iconLabelGap,
    required this.itemStyle,
    required this.twoTabDarkBackground,
  });

  final double height;
  final Color backgroundColor;
  final List<BoxShadow> shadow;
  final double iconSize;
  final double iconLabelGap;
  final BottomNavItemStyleSpec itemStyle;
  final Color? twoTabDarkBackground;
}

@immutable
class AppBottomNavTheme extends ThemeExtension<AppBottomNavTheme> {
  const AppBottomNavTheme({required this.spec});

  final BottomNavStyleSpec spec;

  @override
  AppBottomNavTheme copyWith({BottomNavStyleSpec? spec}) {
    return AppBottomNavTheme(spec: spec ?? this.spec);
  }

  @override
  AppBottomNavTheme lerp(covariant AppBottomNavTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppBottomNavThemeX on BuildContext {
  AppBottomNavTheme get appBottomNavTheme =>
      Theme.of(this).extension<AppBottomNavTheme>()!;
}

abstract final class BottomNavTokens {
  BottomNavTokens._();

  static AppBottomNavTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppBottomNavTheme(
      spec: resolve(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static BottomNavStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final clear = colors.palettes.white.withValues(alpha: 0);

    final labelBase = typography.smallNormal.copyWith(
      fontSize: 14.rfs,
      height: 12 / 14,
    );

    return BottomNavStyleSpec(
      height: AppDimension.buttonLg,
      backgroundColor: isDark ? colors.background : colors.surface,
      shadow: isDark ? const [] : AppShadows.small,
      iconSize: AppDimension.iconMenu,
      iconLabelGap: AppSpacing.sm,
      twoTabDarkBackground: isDark ? colors.textDisabled : null,
      itemStyle: BottomNavItemStyleSpec(
        selectedLabelStyle: labelBase.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.primary,
        ),
        unselectedLabelStyle: labelBase.copyWith(
          fontWeight: FontWeight.w500,
          color: colors.textSecondary,
        ),
        selectedIconColor: colors.primary,
        unselectedIconColor: colors.textSecondary,
        itemBackgroundColor: isDark ? colors.controlFill : clear,
      ),
    );
  }

  static BottomNavigationBarThemeData bottomNavigationBarTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final spec = resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return BottomNavigationBarThemeData(
      backgroundColor: spec.backgroundColor,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: spec.itemStyle.selectedIconColor,
      unselectedItemColor: spec.itemStyle.unselectedIconColor,
      selectedLabelStyle: spec.itemStyle.selectedLabelStyle,
      unselectedLabelStyle: spec.itemStyle.unselectedLabelStyle,
    );
  }
}
