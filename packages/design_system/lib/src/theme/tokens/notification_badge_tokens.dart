import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:design_system/src/theme/typography/responsive_font_scale.dart';
import 'package:flutter/material.dart';

@immutable
class NotificationBadgeStyleSpec {
  const NotificationBadgeStyleSpec({
    required this.size,
    required this.borderRadius,
    required this.backgroundColor,
    required this.textStyle,
  });

  final double size;
  final BorderRadius borderRadius;
  final Color backgroundColor;
  final TextStyle textStyle;
}

/// Figma `Views / Badges: Notifications: Rounded` (`40:10681` / `73:2910`).
abstract final class NotificationBadgeTokens {
  NotificationBadgeTokens._();

  /// Figma `Red/Base` used by notification count badges.
  static const Color _redBase = Color(0xFFFF5247);

  static NotificationBadgeStyleSpec resolve({
    required AppTypography typography,
    required AppColors colors,
  }) {
    return NotificationBadgeStyleSpec(
      size: AppDimension.notificationBadgeSize,
      borderRadius: BorderRadius.circular(AppDimension.radiusXs),
      backgroundColor: _redBase,
      textStyle: typography.tinyNormal.copyWith(
        fontSize: 10.rfs,
        height: 16 / 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 0,
        color: colors.onError,
      ),
    );
  }
}
