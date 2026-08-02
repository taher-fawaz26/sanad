import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/presentation/widgets/asset_picker_tile.dart';
import 'package:asset_picker/src/theme/asset_picker_theme.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// A design-system bottom sheet that lets the user choose an [AssetSource].
///
/// Figma `Menu` action sheet (`2947:14236`).
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

  /// Enabled sources in presentation order:
  /// files → scanner → gallery → camera.
  List<AssetSource> get _enabledSources => [
    if (options.allowFiles) AssetSource.files,
    if (options.allowScanner) AssetSource.scanner,
    if (options.allowGallery) AssetSource.gallery,
    if (options.allowCamera) AssetSource.camera,
  ];

  @override
  Widget build(BuildContext context) {
    final colors = theme.colors;
    final sources = _enabledSources;
    final title = options.sheetTitle ?? theme.texts.sheetTitle;
    final subtitle = options.subtitle;

    return Material(
      color: colors.surface,
      borderRadius: theme.sheetRadius,
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (theme.showDragHandle) _DragHandle(theme: theme),
            SizedBox(height: AppSpacing.lg),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: theme.horizontalPadding,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.titleStyle),
                  if (subtitle != null && subtitle.isNotEmpty) ...[
                    SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: theme.subtitleStyle),
                  ],
                ],
              ),
            ),
            for (var i = 0; i < sources.length; i++)
              AssetPickerTile(
                source: sources[i],
                theme: theme,
                showBottomBorder: i < sources.length - 1,
                onTap: () => Navigator.of(context).pop(sources[i]),
              ),
            Divider(height: 1, color: colors.divider),
            Material(
              color: colors.surface,
              child: InkWell(
                onTap: () => Navigator.of(context).pop(),
                child: SizedBox(
                  height: theme.cancelHeight,
                  child: Center(
                    child: Text(
                      theme.texts.cancel,
                      style: theme.cancelStyle,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
          ],
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
    return SizedBox(
      height: responsiveDimension(24),
      child: Padding(
        padding: EdgeInsets.only(top: theme.dragHandleTopPadding),
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
  final appColors = context.appColors;
  final typography = context.appTypography;
  final brightness = Theme.of(context).brightness;
  final actionSpec = ActionSheetTokens.resolve(
    colors: appColors,
    typography: typography,
    brightness: brightness,
  );

  return showModalBottomSheet<AssetSource>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: actionSpec.barrierColor,
    showDragHandle: false,
    builder: (_) => AssetSourceSheet(options: options, theme: theme),
  );
}
