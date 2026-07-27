import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/presentation/widgets/asset_picker_tile.dart';
import 'package:asset_picker/src/theme/asset_picker_theme.dart';
import 'package:flutter/material.dart';

/// A design-system bottom sheet that lets the user choose an [AssetSource].
///
/// The sheet **generates itself** from [AssetPickerOptions]: it renders exactly
/// one row per enabled source (`allowCamera`, `allowGallery`, `allowFiles`,
/// `allowScanner`) in a stable order, and nothing is hardcoded. Adding a source
/// to the enum + options makes it appear here automatically.
///
/// Returns the chosen [AssetSource], or `null` if the user dismissed the sheet.
class AssetSourceSheet extends StatelessWidget {
  const AssetSourceSheet({
    required this.options,
    required this.theme,
    super.key,
  });

  final AssetPickerOptions options;
  final AssetPickerTheme theme;

  /// The enabled sources, in a stable presentation order.
  List<AssetSource> get _enabledSources => [
    if (options.allowCamera) AssetSource.camera,
    if (options.allowGallery) AssetSource.gallery,
    if (options.allowFiles) AssetSource.files,
    if (options.allowScanner) AssetSource.scanner,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final sources = _enabledSources;
    final title = options.sheetTitle ?? theme.texts.sheetTitle;
    final subtitle = options.subtitle;
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Material(
      color: colors.surface,
      borderRadius: theme.sheetRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (theme.showDragHandle) _DragHandle(theme: theme),
              Padding(
                padding: theme.contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.titleStyle),
                    if (subtitle != null && subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(subtitle, style: theme.subtitleStyle),
                    ],
                    const SizedBox(height: 8),
                    for (var i = 0; i < sources.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.divider),
                      AssetPickerTile(
                        source: sources[i],
                        theme: theme,
                        onTap: () => Navigator.of(context).pop(sources[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.theme});

  final AssetPickerTheme theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: Center(
        child: Container(
          width: theme.dragHandleWidth,
          height: theme.dragHandleHeight,
          decoration: BoxDecoration(
            color: theme.colors.dragHandle,
            borderRadius: BorderRadius.circular(theme.dragHandleHeight),
          ),
        ),
      ),
    );
  }
}

/// Shows [AssetSourceSheet] and resolves to the chosen source, or `null` when
/// dismissed.
Future<AssetSource?> showAssetSourceSheet({
  required BuildContext context,
  required AssetPickerOptions options,
  required AssetPickerTheme theme,
}) {
  return showModalBottomSheet<AssetSource>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => AssetSourceSheet(options: options, theme: theme),
  );
}
