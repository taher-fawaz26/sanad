import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';

/// Abstraction over "browse and pick files from the file system".
///
/// Supports extension filtering via
/// [AssetPickerOptions.resolvedAllowedExtensions]. The concrete implementation
/// is the sole owner of the underlying file-picker plugin.
abstract class FileProvider {
  Future<List<PickedAsset>> pick(AssetPickerOptions options);
}
