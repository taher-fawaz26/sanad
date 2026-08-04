import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Edit action button for a general settings view-mode section.
class SettingsEditButton extends StatelessWidget {
  /// Creates the settings edit button placeholder.
  ///

  const SettingsEditButton({
    super.key,
    this.title,
    this.subtitle,
    required this.colors,
    required this.typography,
    this.onEdit,
  });

  final AppColors colors;
  final AppTypography typography;
  final VoidCallback? onEdit;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xs,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: typography.regularNone.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: typography.smallNormal.copyWith(
                    fontSize: 13,
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w400,
                  ),
                ),
            ],
          ),
        ),
        if (onEdit != null)
          GestureDetector(
            onTap: onEdit,
            child: AppSvgPicture.asset(
              AppSvgs.branchEdit,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                colors.textSecondary,
                BlendMode.srcIn,
              ),
            ),
          ),
      ],
    );
  }
}
