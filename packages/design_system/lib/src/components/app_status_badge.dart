import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/status_badge_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma `Views / Status Badges` (`40:10689`, `40:10672`).
class AppStatusBadge extends StatelessWidget {
  const AppStatusBadge({
    required this.label, required this.type, super.key,
  });

  final String label;
  final AppStatusBadgeType type;

  @override
  Widget build(BuildContext context) {
    final spec = StatusBadgeTokens.resolve(
      type: type,
      typography: context.appTypography,
      colors: context.appColors,
    );

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: spec.horizontalPadding,
        vertical: spec.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: spec.backgroundColor,
        borderRadius: spec.borderRadius,
      ),
      child: Text(label, style: spec.textStyle),
    );
  }
}
