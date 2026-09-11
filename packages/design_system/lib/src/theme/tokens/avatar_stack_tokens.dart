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

/// How the "+N" overflow chip at the end of the stack is coloured.
///
/// The glyph, the sizes and the white ring are the same in both — only the
/// chip's own fill and label change, which is why this is a tone on one
/// component rather than a second stack.
enum AppAvatarStackTone {
  /// Figma team avatar stack (`194:2647`) — brand mint chip.
  brand,

  /// Figma request card `More_Indicator` (`8385:4404`) — the softer green
  /// pair the status badges already use (`#ECFCE5` on `#198155`).
  success,
}

/// Figma team avatar stack (`194:2647`) token resolver.
abstract final class AvatarStackTokens {
  AvatarStackTokens._();

  static const double avatarSize = 32;

  /// Figma `194:2647` overlaps by 12; the request card's stack
  /// (`8385:4400`) draws the same 32dp avatars at `mr-[-10px]`.
  static const double overlap = 12;
  static const double successOverlap = 10;
  static const double borderWidth = 2;

  static AvatarStackStyleSpec resolve({
    required AppColors colors,
    required AppTypography typography,
    AppAvatarStackTone tone = AppAvatarStackTone.brand,
  }) {
    final isSuccess = tone == AppAvatarStackTone.success;
    return AvatarStackStyleSpec(
      avatarSize: responsiveDimension(avatarSize),
      overlap: responsiveDimension(isSuccess ? successOverlap : overlap),
      borderWidth: responsiveDimension(borderWidth),
      borderColor: colors.surface,
      overflowBackground: isSuccess
          ? colors.successContainer
          : colors.palettes.main.shade100,
      overflowTextStyle: typography.smallNormal.copyWith(
        fontSize: isSuccess ? 11.rfs : 12.rfs,
        height: isSuccess ? 16 / 11 : 16 / 12,
        fontWeight: isSuccess ? FontWeight.w600 : FontWeight.w500,
        color: isSuccess ? colors.onSuccessContainer : colors.primary,
      ),
    );
  }
}
