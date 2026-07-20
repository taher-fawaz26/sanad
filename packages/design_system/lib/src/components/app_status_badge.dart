import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/status_badge_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Badges: Status: Rounded` (`40:10689`).
///
/// Soft fill + matching label color. View-only — not interactive.
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label,
    required this.type,
    super.key,
    this.size = AppStatusBadgeSize.medium,
    this.outlined = false,
  });

  final String label;
  final AppStatusBadgeType type;
  final AppStatusBadgeSize size;

  /// When true, draws a primary stroke — Figma worker badge (`1526:12324`).
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    final spec = StatusBadgeTokens.resolve(
      type: type,
      size: size,
      typography: context.appTypography,
      colors: context.appColors,
      outlined: outlined,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
        border: spec.borderColor != null
            ? Border.all(
                color: spec.borderColor!,
                width: AppDimension.borderHairline,
              )
            : null,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: spec.height ?? 0,
          maxHeight: spec.height ?? double.infinity,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spec.horizontalPadding,
            vertical: spec.height == null ? spec.verticalPadding : 0,
          ),
          child: Center(
            child: Text(
              label,
              style: spec.textStyle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
