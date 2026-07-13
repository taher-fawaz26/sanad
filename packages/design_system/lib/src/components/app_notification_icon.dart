import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Header notification bell with optional unread indicator dot.
///
/// Distinct from [AppNotificationBadge] (numeric count badge).
class AppNotificationIcon extends StatelessWidget {
  const AppNotificationIcon({
    super.key,
    this.hasUnread = false,
    this.onTap,
    this.size,
    this.iconColor,
    this.unreadDotColor,
  });

  final bool hasUnread;
  final VoidCallback? onTap;
  final double? size;
  final Color? iconColor;
  final Color? unreadDotColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dimension = size ?? AppDimension.iconMenu;
    final strokeColor = iconColor ?? colors.textPrimary;
    final dotColor = unreadDotColor ?? colors.primary;

    final bell = AppSvgPicture.asset(
      AppSvgs.notification,
      width: dimension,
      height: dimension,
      colorFilter: ColorFilter.mode(strokeColor, BlendMode.srcIn),
    );

    final icon = hasUnread
        ? Stack(
            clipBehavior: Clip.none,
            children: [
              bell,
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: dimension * 0.33,
                  height: dimension * 0.33,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.surface, width: 1.5),
                  ),
                ),
              ),
            ],
          )
        : bell;

    if (onTap == null) {
      return icon;
    }

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: icon,
    );
  }
}
