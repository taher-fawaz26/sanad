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
  });

  final ImageProvider? image;
  final String? initials;
  final AppAvatarSize size;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spec = AvatarTokens.resolve(
      avatarSize: size,
      colors: colors,
      initialsStyle: typography.regularNormal,
    );

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
          style: spec.initialsStyle,
        ),
      );
    } else {
      child = const SizedBox.shrink();
    }

    return ClipRRect(
      borderRadius: spec.borderRadius,
      child: Container(
        width: spec.size,
        height: spec.size,
        color: spec.placeholderColor,
        child: child,
      ),
    );
  }
}
