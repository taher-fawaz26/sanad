import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
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

/// Figma `Views / Notification Badges` (`40:10681`) token resolver.
abstract final class NotificationBadgeTokens {
  NotificationBadgeTokens._();

  static NotificationBadgeStyleSpec resolve({
    required AppTypography typography,
    required AppColors colors,
  }) {
    return NotificationBadgeStyleSpec(
      size: AppDimension.notificationBadgeSize,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      backgroundColor: colors.error,
      textStyle: typography.regularNormal.copyWith(
        fontWeight: FontWeight.w700,
        color: colors.onError,
      ),
    );
  }
}
