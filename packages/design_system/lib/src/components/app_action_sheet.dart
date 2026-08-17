import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/action_sheet_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// One row in [AppActionList].
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

/// Chrome-free list of tappable action rows — Figma `Views / Action Sheets`
/// (`40:9109`) reduced to just its item rows.
///
/// Pair with `SheetNavigator.push` (settings: `SheetRouteSettings(padChild:
/// false)`); the surrounding surface, radius, drag handle, and barrier come
/// from `SheetNavigation`'s own chrome — this widget owns only the rows.
/// Dismissing without a selection is done via the sheet's barrier/drag, not
/// a dedicated cancel row.
class AppActionList extends StatelessWidget {
  const AppActionList({required this.items, super.key});

  final List<AppActionSheetItem> items;

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

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: spec.dividerColor),
            _ActionListRow(item: items[i], spec: spec, colors: colors),
          ],
        ],
      ),
    );
  }
}

class _ActionListRow extends StatelessWidget {
  const _ActionListRow({
    required this.item,
    required this.spec,
    required this.colors,
  });

  final AppActionSheetItem item;
  final ActionSheetStyleSpec spec;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final style = spec.itemStyle.copyWith(
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
