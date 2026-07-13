import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/notification_badge_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Notification Badges` (`40:10681`).
class AppNotificationBadge extends StatelessWidget {
  const AppNotificationBadge({
    required this.count, super.key,
    this.maxCount = 99,
  });

  final int count;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) {
      return const SizedBox.shrink();
    }

    final spec = NotificationBadgeTokens.resolve(
      typography: context.appTypography,
      colors: context.appColors,
    );
    final label = count > maxCount ? '$maxCount+' : '$count';

    return Container(
      width: spec.size,
      height: spec.size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
      ),
      child: Text(label, style: spec.textStyle),
    );
  }
}
