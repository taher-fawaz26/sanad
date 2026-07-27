import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';

/// Abstraction over "scan a physical document".
///
/// A scanner performs edge detection, perspective correction and cropping,
/// then returns one [PickedAsset] per page (JPEG today; multi-page and PDF
/// output are future-ready without changing this contract).
///
/// The concrete implementation is the sole owner of the underlying document
/// scanning SDK, so swapping `document_camera_frame` for `flutter_doc_scanner`
/// or a native module is a one-class change with zero feature impact.
abstract class ScannerProvider {
  Future<List<PickedAsset>> scan(AssetPickerOptions options);
}
