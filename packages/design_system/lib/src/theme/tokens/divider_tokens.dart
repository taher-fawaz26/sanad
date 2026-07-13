import 'package:design_system/design_system.dart' show AppDivider;
import 'package:design_system/src/components/app_divider.dart' show AppDivider;
import 'package:design_system/src/components/components.dart' show AppDivider;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma divider thickness (`53:2097`).
enum AppDividerThickness {
  thin,
  thick,
}

/// Resolved styling for [AppDivider].
@immutable
class DividerStyleSpec {
  const DividerStyleSpec({
    required this.thinHeight,
    required this.thickHeight,
    required this.thinColor,
    required this.thickColor,
    required this.paddedInset,
  });

  final double thinHeight;
  final double thickHeight;
  final Color thinColor;
  final Color thickColor;
  final double paddedInset;
}

/// Figma `Views / Dividers` (`53:2097`) token resolver.
abstract final class DividerTokens {
  DividerTokens._();

  static const double thinHeight = 1;
  static const double thickHeight = 12;
  static const double paddedInset = 24;

  static DividerStyleSpec resolve({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final dark = colors.palettes.dark;
    final isDark = brightness == Brightness.dark;

    return DividerStyleSpec(
      thinHeight: responsiveDimension(thinHeight),
      thickHeight: responsiveDimension(thickHeight),
      thinColor: isDark ? dark.shade900 : dark.shade100,
      thickColor: isDark ? dark.shade900 : dark.shade50,
      paddedInset: responsiveDimension(paddedInset),
    );
  }

  static DividerThemeData dividerTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    final spec = resolve(colors: colors, brightness: brightness);

    return DividerThemeData(
      color: spec.thinColor,
      thickness: spec.thinHeight,
      space: spec.thinHeight,
    );
  }
}
