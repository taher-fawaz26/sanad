import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/theme/asset_picker_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A single selectable source row inside `AssetSourceSheet`.
///
/// Figma `Views / Tables` row (`2947:14240`–`2947:14242`).
class AssetPickerTile extends StatelessWidget {
  const AssetPickerTile({
    required this.source,
    required this.theme,
    required this.onTap,
    this.showBottomBorder = true,
    super.key,
  });

  final AssetSource source;
  final AssetPickerTheme theme;
  final VoidCallback onTap;
  final bool showBottomBorder;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: showBottomBorder
                ? Border(
                    bottom: BorderSide(color: colors.rowDivider),
                  )
                : null,
          ),
          child: SizedBox(
            height: theme.itemHeight,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.horizontalPadding,
              ),
              child: Row(
                children: [
                  AppSvgPicture.asset(
                    theme.icons.iconPathFor(source),
                    width: theme.leadingIconSize,
                    height: theme.leadingIconSize,
                    colorFilter: ColorFilter.mode(
                      colors.icon,
                      BlendMode.srcIn,
                    ),
                  ),
                  SizedBox(width: theme.itemHorizontalGap),
                  Expanded(
                    child: Text(
                      theme.texts.labelFor(source),
                      style: theme.tileTitleStyle,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
