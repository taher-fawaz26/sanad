import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/avatar_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Images: Avatars` (`40:8349`).
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.image,
    this.initials,
    this.size = AppAvatarSize.medium,
    this.backgroundColor,
    this.showStatusDot = false,
    this.statusColor,
  });

  final ImageProvider? image;
  final String? initials;
  final AppAvatarSize size;
  final Color? backgroundColor;
  final bool showStatusDot;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spec = AvatarTokens.resolve(
      avatarSize: size,
      colors: colors,
      initialsStyle: typography.regularNormal,
    );

    final fillColor = backgroundColor ?? spec.placeholderColor;
    final dotColor = statusColor ?? colors.success;

    Widget child;
    if (image != null) {
      child = Image(
        image: image!,
        width: spec.size,
        height: spec.size,
        fit: BoxFit.cover,
      );
    } else if (initials != null && initials!.isNotEmpty) {
      child = Center(
        child: Text(
          initials!,
          style: spec.initialsStyle.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }

    final avatar = ClipRRect(
      borderRadius: spec.borderRadius,
      child: Container(
        width: spec.size,
        height: spec.size,
        color: fillColor,
        child: child,
      ),
    );

    if (!showStatusDot) {
      return avatar;
    }

    final dotSize = spec.size * 0.3;

    return SizedBox(
      width: spec.size,
      height: spec.size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          avatar,
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.surface,
                  width: 2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
