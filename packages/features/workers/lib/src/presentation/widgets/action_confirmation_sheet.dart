import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

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

Future<bool?> showWorkerConfirmationSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String actionLabel,
  required String cancelLabel,
  AppButtonType actionType = AppButtonType.primary,
  bool destructive = false,
}) {
  return SheetNavigator.push<bool>(
    context,
    AppConfirmationContent(
      title: title,
      description: description,
      actionLabel: actionLabel,
      cancelLabel: cancelLabel,
      actionType: actionType,
      destructive: destructive,
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.expanded,
      padChild: false,
    ),
  );
}
