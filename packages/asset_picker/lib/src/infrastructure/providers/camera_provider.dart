import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';

/// Abstraction over "capture from the device camera".
///
/// Concrete implementations (e.g. `ImagePickerCameraProvider`) live in
/// `infrastructure/implementations` and are the *only* place a third-party
/// camera plugin is referenced. Features depend on this interface, never on
/// the plugin.
///
/// Returns the captured assets, an empty list if the user backed out, and
/// throws an `AssetPickerException` on permission/platform failure.
abstract class CameraProvider {
  Future<List<PickedAsset>> capture(AssetPickerOptions options);
}
