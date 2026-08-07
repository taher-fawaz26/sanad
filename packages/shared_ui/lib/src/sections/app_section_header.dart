import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Title / subtitle row with an optional trailing edit action.
///
/// Domain-agnostic header used inside section cards and similar surfaces.
class AppSectionHeader extends StatelessWidget {
  /// Creates a section header.
  const AppSectionHeader({
    super.key,
    this.title,
    this.subtitle,
    this.onEdit,
  });

  /// Primary heading text.
  final String? title;

  /// Secondary supporting text under [title].
  final String? subtitle;

  /// When non-null, shows a trailing edit icon that invokes this callback.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.lg,
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
          InkWell(
            onTap: onEdit,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: AppSvgPicture.asset(
                AppSvgs.branchEdit,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(
                  colors.textPrimary,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
