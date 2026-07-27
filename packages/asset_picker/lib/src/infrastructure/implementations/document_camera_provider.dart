import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/domain/failures/asset_picker_exception.dart';
import 'package:asset_picker/src/infrastructure/providers/scanner_provider.dart';
import 'package:asset_picker/src/utils/asset_mime_resolver.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

/// Built-in default [ScannerProvider] that produces a JPEG document capture.
///
/// ### Why this ships as the default
/// The package's contract is "return a [PickedAsset] JPEG from a document
/// capture". This implementation fulfils that contract today using the camera,
/// with **zero extra native dependencies**, so the package builds and runs on
/// every platform out of the box.
///
/// ### Upgrading to a full scanner SDK
/// Edge detection, perspective correction, auto-cropping, multi-page capture
/// and PDF generation are provided by dedicated SDKs such as
/// `document_camera_frame` or `flutter_doc_scanner`. Because [ScannerProvider]
/// is an interface, dropping one in is a **single-class change**: implement
/// [ScannerProvider] with the SDK, then register it via
/// `AssetPickerConfig.scannerProvider` — no feature code changes, and the
/// `AssetPicker.scanDocument()` API stays identical.
///
/// Multi-page and PDF output are future-ready: this method returns a
/// `List<PickedAsset>` (one page today) so a multi-page SDK needs no signature
/// change.
class DocumentCameraScannerProvider implements ScannerProvider {
  DocumentCameraScannerProvider({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedAsset>> scan(AssetPickerOptions options) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        // Scans are always compressed to a reasonable JPEG quality.
        imageQuality: options.enableCompression ? options.imageQuality : 90,
      );
      if (file == null) return const [];

      final size = await file.length();
      final mimeType =
          file.mimeType ?? AssetMimeResolver.fromFileName(file.name);
      return [
        PickedAsset(
          name: file.name,
          path: file.path,
          bytes: options.loadBytes ? await file.readAsBytes() : null,
          mimeType: mimeType,
          size: size,
          // A scan is always classified as an image (JPEG) today.
          assetType: AssetType.image,
        ),
      ];
    } on PlatformException catch (e) {
      final code = e.code.toLowerCase();
      if (code.contains('access_denied') || code.contains('permission')) {
        throw AssetPermissionDeniedException(
          AssetSource.scanner,
          permanentlyDenied: true,
          message: e.message ?? 'Camera access denied for scanning.',
        );
      }
      throw AssetPickerPlatformException(
        e.message ?? 'Document scan failed.',
        source: AssetSource.scanner,
        cause: e,
      );
    }
  }
}
