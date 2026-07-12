import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppMapLinkCard].
@immutable
class MapLinkCardStyleSpec {
  const MapLinkCardStyleSpec({
    required this.padding,
    required this.borderRadius,
    required this.backgroundColor,
    required this.borderColor,
    required this.contentGap,
    required this.iconSize,
    required this.titleStyle,
    required this.captionStyle,
    required this.trailingIconSize,
    required this.trailingIconColor,
  });

  final EdgeInsets padding;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double contentGap;
  final double iconSize;
  final TextStyle titleStyle;
  final TextStyle captionStyle;
  final double trailingIconSize;
  final Color trailingIconColor;
}

/// Figma location map link card (`194:2647`) token resolver.
abstract final class MapLinkCardTokens {
  MapLinkCardTokens._();

  static const double borderRadius = 8;
  static const double iconSize = 24;

  static MapLinkCardStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    required Brightness brightness,
  }) {
    final isDark = brightness == Brightness.dark;
    final sky = colors.palettes.sky;

    return MapLinkCardStyleSpec(
      padding: EdgeInsets.all(responsiveSpacing(16)),
      borderRadius: BorderRadius.circular(responsiveDimension(borderRadius)),
      backgroundColor: isDark ? sky.shade900 : sky.shade50,
      borderColor: isDark ? sky.shade700 : sky.shade200,
      contentGap: AppSpacing.md,
      iconSize: responsiveDimension(iconSize),
      titleStyle: typography.regularNormal.copyWith(
        fontSize: 16.rfs,
        height: 20 / 16,
        fontWeight: FontWeight.w400,
        color: colors.textPrimary,
      ),
      captionStyle: typography.smallNormal.copyWith(
        fontSize: 14.rfs,
        height: 16 / 14,
        fontWeight: FontWeight.w400,
        color: colors.primary,
      ),
      trailingIconSize: responsiveDimension(iconSize),
      trailingIconColor: colors.primary,
    );
  }
}
