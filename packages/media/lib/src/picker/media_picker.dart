import 'package:asset_picker/asset_picker.dart';
import 'package:media/src/config/media_picker_config.dart';
import 'package:media/src/models/media_source.dart';

/// Thin wrapper over the `asset_picker` facade, scoped by [MediaPickerConfig].
///
/// The only place in the package that talks to `asset_picker`. Returns the
/// raw [PickedAsset] (or `null` if cancelled); validation and processing
/// happen downstream.
abstract final class MediaPicker {
  MediaPicker._();

  static Future<PickedAsset?> pick({
    required MediaSource source,
    required MediaPickerConfig config,
  }) async {
    final options = config.toAssetPickerOptions();
    final result = switch (source) {
      AssetSource.gallery => await AssetPicker.pickGallery(options: options),
      AssetSource.files => await AssetPicker.pickFile(options: options),
      AssetSource.camera => await AssetPicker.pickCamera(options: options),
      AssetSource.scanner => await AssetPicker.scanDocument(options: options),
    };
    if (result.cancelled) return null;
    return result.single;
  }
}
