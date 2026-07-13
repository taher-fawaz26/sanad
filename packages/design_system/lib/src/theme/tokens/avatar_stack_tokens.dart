import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

/// Resolved styling for [AppAvatarStack].
@immutable
class AvatarStackStyleSpec {
  const AvatarStackStyleSpec({
    required this.avatarSize,
    required this.overlap,
    required this.borderWidth,
    required this.borderColor,
    required this.overflowBackground,
    required this.overflowTextStyle,
  });

  final double avatarSize;
  final double overlap;
  final double borderWidth;
  final Color borderColor;
  final Color overflowBackground;
  final TextStyle overflowTextStyle;
}

/// Figma team avatar stack (`194:2647`) token resolver.
abstract final class AvatarStackTokens {
  AvatarStackTokens._();

  static const double avatarSize = 32;
  static const double overlap = 12;
  static const double borderWidth = 2;

  static AvatarStackStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
  }) {
    return AvatarStackStyleSpec(
      avatarSize: responsiveDimension(avatarSize),
      overlap: responsiveDimension(overlap),
      borderWidth: responsiveDimension(borderWidth),
      borderColor: colors.surface,
      overflowBackground: colors.palettes.main.shade100,
      overflowTextStyle: typography.smallNormal.copyWith(
        fontSize: 12.rfs,
        height: 16 / 12,
        fontWeight: FontWeight.w500,
        color: colors.primary,
      ),
    );
  }
}
