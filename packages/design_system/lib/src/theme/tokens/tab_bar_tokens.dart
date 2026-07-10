import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

@immutable
class TabBarStyleSpec {
  const TabBarStyleSpec({
    required this.height,
    required this.backgroundColor,
    required this.selectedLabelColor,
    required this.unselectedLabelColor,
    required this.indicatorColor,
    required this.indicatorWeight,
    required this.indicatorBorderRadius,
    required this.labelStyle,
    required this.unselectedLabelStyle,
    required this.dividerColor,
    required this.overlayColor,
  });

  final double height;
  final Color backgroundColor;
  final Color selectedLabelColor;
  final Color unselectedLabelColor;
  final Color indicatorColor;
  final double indicatorWeight;
  final BorderRadius indicatorBorderRadius;
  final TextStyle labelStyle;
  final TextStyle unselectedLabelStyle;
  final Color dividerColor;
  final WidgetStateProperty<Color?> overlayColor;
}

@immutable
class AppTabBarTheme extends ThemeExtension<AppTabBarTheme> {
  const AppTabBarTheme({required this.spec});

  final TabBarStyleSpec spec;

  @override
  AppTabBarTheme copyWith({TabBarStyleSpec? spec}) {
    return AppTabBarTheme(spec: spec ?? this.spec);
  }

  @override
  AppTabBarTheme lerp(covariant AppTabBarTheme? other, double t) {
    if (other == null) {
      return this;
    }
    return t < 0.5 ? this : other;
  }
}

extension AppTabBarThemeX on BuildContext {
  AppTabBarTheme get appTabBarTheme =>
      Theme.of(this).extension<AppTabBarTheme>()!;
}

abstract final class TabBarTokens {
  TabBarTokens._();

  static AppTabBarTheme themeExtension({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    return AppTabBarTheme(
      spec: resolve(
        colors: colors,
        typography: typography,
        brightness: brightness,
      ),
    );
  }

  static TabBarStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final clear = colors.palettes.white.withValues(alpha: 0);

    final labelStyle = typography.bodyMedium.copyWith(
      fontSize: 16.rfs,
      height: 1,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
    );

    return TabBarStyleSpec(
      height: AppDimension.buttonMd,
      backgroundColor: isDark ? colors.background : colors.surface,
      selectedLabelColor: colors.primary,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.primary,
      indicatorWeight: AppDimension.borderHairline,
      indicatorBorderRadius: BorderRadius.circular(AppDimension.radiusXs / 2),
      labelStyle: labelStyle.copyWith(color: colors.primary),
      unselectedLabelStyle: labelStyle.copyWith(color: colors.textSecondary),
      dividerColor: clear,
      overlayColor: WidgetStateProperty.all(clear),
    );
  }

  static TabBarThemeData tabBarTheme({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final spec = resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return TabBarThemeData(
      labelColor: spec.selectedLabelColor,
      unselectedLabelColor: spec.unselectedLabelColor,
      indicatorColor: spec.indicatorColor,
      indicatorSize: TabBarIndicatorSize.tab,
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: spec.indicatorColor,
          width: spec.indicatorWeight,
        ),
        borderRadius: spec.indicatorBorderRadius,
      ),
      dividerColor: spec.dividerColor,
      dividerHeight: 0,
      labelStyle: spec.labelStyle,
      unselectedLabelStyle: spec.unselectedLabelStyle,
      overlayColor: spec.overlayColor,
      splashFactory: NoSplash.splashFactory,
    );
  }
}
