import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/action_sheet_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// One row in [AppActionSheet].
class AppActionSheetItem {
  const AppActionSheetItem({
    required this.label,
    required this.onTap,
    this.leading,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback onTap;

  /// Optional 24dp leading icon (Figma `Views / Action Sheets`, `40:9109`).
  final Widget? leading;
  final bool isDestructive;
}

/// Figma `Views / Action Sheets` (`40:9109`).
class AppActionSheet extends StatelessWidget {
  const AppActionSheet({
    required this.items, super.key,
    this.title,
    this.cancelLabel = 'Cancel',
    this.onCancel,
  });

  final String? title;
  final List<AppActionSheetItem> items;
  final String cancelLabel;
  final VoidCallback? onCancel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final brightness = Theme.of(context).brightness;
    final spec = ActionSheetTokens.resolve(
      colors: colors,
      typography: typography,
      brightness: brightness,
    );

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: spec.surfaceColor,
              borderRadius: spec.topRadius,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null) ...[
                  SizedBox(height: AppSpacing.lg),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: spec.horizontalPadding,
                    ),
                    child: Text(title!, style: spec.titleStyle),
                  ),
                  SizedBox(height: AppSpacing.sm),
                ],
                for (var i = 0; i < items.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: spec.dividerColor),
                  _ActionSheetRow(
                    item: items[i],
                    spec: spec,
                    colors: colors,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Container(
            decoration: BoxDecoration(
              color: spec.surfaceColor,
              borderRadius: spec.topRadius,
            ),
            child: _ActionSheetRow(
              item: AppActionSheetItem(
                label: cancelLabel,
                onTap: onCancel ?? () => Navigator.of(context).pop(),
              ),
              spec: spec,
              colors: colors,
              isCancel: true,
            ),
          ),
          SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}

class _ActionSheetRow extends StatelessWidget {
  const _ActionSheetRow({
    required this.item,
    required this.spec,
    required this.colors,
    this.isCancel = false,
  });

  final AppActionSheetItem item;
  final ActionSheetStyleSpec spec;
  final AppColors colors;
  final bool isCancel;

  @override
  Widget build(BuildContext context) {
    final style = isCancel
        ? spec.cancelStyle
        : spec.itemStyle.copyWith(
            color: item.isDestructive ? colors.error : colors.textPrimary,
          );
    final leading = item.leading;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          item.onTap();
        },
        child: SizedBox(
          height: spec.itemHeight,
          child: leading == null
              ? Center(child: Text(item.label, style: style))
              : Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: spec.horizontalPadding,
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: spec.leadingIconSize,
                        height: spec.leadingIconSize,
                        child: leading,
                      ),
                      SizedBox(width: spec.itemHorizontalGap),
                      Expanded(child: Text(item.label, style: style)),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Shows a Figma-styled action sheet.
Future<void> showAppActionSheet({
  required BuildContext context,
  required List<AppActionSheetItem> items, String? title,
  String cancelLabel = 'Cancel',
  VoidCallback? onCancel,
}) {
  final colors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;
  final spec = ActionSheetTokens.resolve(
    colors: colors,
    typography: typography,
    brightness: brightness,
  );

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: spec.barrierColor,
    builder: (context) => AppActionSheet(
      title: title,
      items: items,
      cancelLabel: cancelLabel,
      onCancel: onCancel,
    ),
  );
}
