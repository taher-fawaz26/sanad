import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';

/// Abstraction over "pick from the photo gallery".
///
/// Honours [AssetPickerOptions.allowMultiple] / `maxSelection`. The concrete
/// implementation is the sole owner of the underlying gallery plugin.
abstract class GalleryProvider {
  Future<List<PickedAsset>> pick(AssetPickerOptions options);
}
