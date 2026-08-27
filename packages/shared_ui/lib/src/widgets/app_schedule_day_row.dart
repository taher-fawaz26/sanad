import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma schedule row (`347:14680`, `3821:18513`) with optional delete action
/// (`347:14585`).
class AppScheduleDayRow extends StatelessWidget {
  const AppScheduleDayRow({
    required this.title,
    required this.value,
    super.key,
    this.valueColor,
    this.onDelete,
    this.deleteSemanticLabel,
  });

  final String title;
  final String value;
  final Color? valueColor;
  final VoidCallback? onDelete;

  /// Accessibility label for the delete action. Falls back to [title] when
  /// omitted — callers should pass a real localized label (e.g. "Delete").
  final String? deleteSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final spec = KeyValueCardTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: Theme.of(context).brightness,
    );

    return Material(
      color: spec.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: spec.borderRadius,
        side: BorderSide(color: spec.borderColor),
      ),
      child: SizedBox(
        height: spec.height,
        width: double.infinity,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: spec.titleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                value,
                style: spec.valueStyle.copyWith(color: valueColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
              if (onDelete != null) ...[
                SizedBox(width: AppSpacing.sm),
                AppIconButton(
                  onTap: onDelete,
                  iconAsset: AppSvgs.trashBold,
                  size: AppIconButtonSize.small,
                  intent: AppButtonIntent.destructive,
                  semanticLabel: deleteSemanticLabel ?? title,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
