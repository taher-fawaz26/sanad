import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Shared confirmation sheet content for destructive/status-change actions
/// across workers and invitations (delete, suspend, resend, cancel).
///
/// Figma `Sheet Content` (`1526:13048`, `1526:13037`, `1526:13026`).
class ActionConfirmationSheet extends StatelessWidget {
  const ActionConfirmationSheet({
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.buttonType,
    required this.destructive,
    required this.cancelLabel,
    super.key,
  });

  final String title;
  final String description;
  final String actionLabel;
  final AppButtonType buttonType;
  final bool destructive;
  final String cancelLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: typography.title2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            description,
            style: typography.regularNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: actionLabel,
            type: buttonType,
            destructive: destructive,
            onPressed: () => Navigator.of(context).pop(true),
          ),
          SizedBox(height: AppSpacing.md),
          AppButton(
            label: cancelLabel,
            type: AppButtonType.outline,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

/// Shared destructive/warning action row used in bottom sheet action lists
/// (e.g. suspend, delete, cancel invitation).
class SheetActionRow extends StatelessWidget {
  const SheetActionRow({
    required this.label,
    required this.color,
    required this.onTap,
    this.icon,
    this.svgAsset,
    super.key,
  });

  final String label;
  final Color color;
  final VoidCallback onTap;
  final IconData? icon;
  final String? svgAsset;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Material(
      color: colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: 18,
          ),
          child: Row(
            children: [
              if (svgAsset != null)
                AppSvgPicture.asset(
                  svgAsset!,
                  width: 24,
                  height: 24,
                  colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
                )
              else if (icon != null)
                Icon(icon, size: 24, color: color),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: typography.regularNormal.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
