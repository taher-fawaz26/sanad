import 'package:asset_picker/asset_picker.dart';
import 'package:flutter/widgets.dart';

/// Runs the [AssetPicker] call matching [source].
///
/// Generic replacement for a feature's bespoke `pickXAsset` helper — the
/// source-to-provider mapping is identical for every flow; only the
/// [AssetPickerOptions] and sheet theming differ per feature.
Future<AssetPickerResult?> pickDocumentAsset(
  AssetSource source,
  AssetPickerOptions options,
) async {
  final result = switch (source) {
    AssetSource.files => await AssetPicker.pickFile(
      options: options.copyWith(allowMultiple: true, maxSelection: 2),
    ),
    AssetSource.camera => await AssetPicker.pickCamera(options: options),
    AssetSource.gallery => await AssetPicker.pickGallery(
      options: options.copyWith(allowMultiple: true, maxSelection: 2),
    ),
    AssetSource.scanner => await AssetPicker.scanDocument(options: options),
  };
  return result.cancelled ? null : result;
}

/// Shows the asset source sheet, then delegates to [pickDocumentAsset].
///
/// Returns `null` if the user cancelled at any point. `theme` and
/// `options.sheetTitle` carry all feature-specific labelling — this function
/// contains no l10n keys of its own.
Future<AssetPickerResult?> captureDocumentAsset(
  BuildContext context, {
  required AssetPickerOptions options,
  required AssetPickerTheme theme,
}) async {
  final source = await showAssetSourceSheet(
    context: context,
    options: options,
    theme: theme,
  );
  if (source == null || !context.mounted) return null;

  return pickDocumentAsset(source, options);
}
