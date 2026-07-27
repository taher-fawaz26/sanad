import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/theme/asset_picker_theme.dart';
import 'package:flutter/material.dart';

/// A single selectable source row inside `AssetSourceSheet`.
///
/// Purely presentational and design-system-driven via [AssetPickerTheme] — it
/// holds no picker logic, so it can be reused to build a custom source UI.
class AssetPickerTile extends StatelessWidget {
  const AssetPickerTile({
    required this.source,
    required this.theme,
    required this.onTap,
    super.key,
  });

  final AssetSource source;
  final AssetPickerTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: theme.tileRadius,
        child: Padding(
          padding: theme.tilePadding,
          child: Row(
            children: [
              Container(
                width: theme.iconContainerSize,
                height: theme.iconContainerSize,
                decoration: BoxDecoration(
                  color: colors.iconBackground,
                  borderRadius: theme.tileRadius,
                ),
                child: Icon(
                  theme.icons.iconFor(source),
                  size: theme.iconSize,
                  color: colors.icon,
                ),
              ),
              SizedBox(width: theme.tileGap),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      theme.texts.labelFor(source),
                      style: theme.tileTitleStyle,
                    ),
                    Text(
                      theme.texts.descriptionFor(source),
                      style: theme.tileSubtitleStyle,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colors.subtitle,
                size: theme.iconSize,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
