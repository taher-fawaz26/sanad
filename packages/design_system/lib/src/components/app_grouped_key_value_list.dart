import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/grouped_key_value_list_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma grouped key/value rows in one rounded container (`365:14910`).
class AppGroupedKeyValueList extends StatelessWidget {
  const AppGroupedKeyValueList({
    required this.items,
    super.key,
  });

  final List<GroupedKeyValueItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final spec = GroupedKeyValueListTokens.resolve(
      colors: context.appColors,
      typography: context.appTypography,
      brightness: Theme.of(context).brightness,
    );

    return Material(
      color: spec.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: spec.borderRadius,
        side: BorderSide(color: spec.borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: spec.dividerColor),
            _GroupedKeyValueRow(item: items[i], spec: spec),
          ],
        ],
      ),
    );
  }
}

class _GroupedKeyValueRow extends StatelessWidget {
  const _GroupedKeyValueRow({required this.item, required this.spec});

  final GroupedKeyValueItem item;
  final GroupedKeyValueListStyleSpec spec;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        child: SizedBox(
          height: spec.rowHeight,
          width: double.infinity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: spec.horizontalPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.title,
                    style: spec.titleStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  item.value,
                  style: spec.valueStyle.copyWith(color: item.valueColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
