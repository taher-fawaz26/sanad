import 'package:design_system/design_system.dart' show AppAvatar;
import 'package:design_system/src/components/app_avatar.dart' show AppAvatar;
import 'package:design_system/src/components/components.dart' show AppAvatar;
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:flutter/material.dart';

/// Figma avatar size tier (`40:8349`).
enum AppAvatarSize {
  /// 24 dp — inline field prefix (`245:6233`).
  small,

  /// 40 dp — table rows and list items (`40:8354`).
  medium,
}

/// Resolved styling for [AppAvatar].
@immutable
class AvatarStyleSpec {
  const AvatarStyleSpec({
    required this.size,
    required this.borderRadius,
    required this.placeholderColor,
    required this.initialsColor,
    required this.initialsStyle,
  });

  final double size;
  final BorderRadius borderRadius;
  final Color placeholderColor;
  final Color initialsColor;
  final TextStyle initialsStyle;
}

/// Figma `Views / Images: Avatars` (`40:8349`) token resolver.
abstract final class AvatarTokens {
  AvatarTokens._();

  static double size(AppAvatarSize avatarSize) => switch (avatarSize) {
        AppAvatarSize.small => AppDimension.iconLg,
        AppAvatarSize.medium => AppDimension.fieldHeightMd,
      };

  static AvatarStyleSpec resolve({
    required AppAvatarSize avatarSize,
    required AppColors colors,
    required TextStyle initialsStyle,
  }) {
    final dimension = size(avatarSize);

    return AvatarStyleSpec(
      size: dimension,
      borderRadius: BorderRadius.circular(dimension / 2),
      placeholderColor: colors.controlFill,
      initialsColor: colors.textSecondary,
      initialsStyle: initialsStyle.copyWith(color: colors.textSecondary),
    );
  }
}
