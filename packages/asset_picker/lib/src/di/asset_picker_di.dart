import 'package:asset_picker/src/di/asset_picker_config.dart';
import 'package:asset_picker/src/domain/services/asset_picker_service.dart';
import 'package:asset_picker/src/infrastructure/implementations/document_camera_frame_scanner_provider.dart';
import 'package:asset_picker/src/infrastructure/implementations/document_camera_provider.dart';
import 'package:asset_picker/src/infrastructure/implementations/file_picker_provider.dart';
import 'package:asset_picker/src/infrastructure/implementations/image_picker_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/scanner_provider.dart';
import 'package:asset_picker/src/infrastructure/services/asset_picker_service_impl.dart';
import 'package:core/core.dart';

/// Registers the asset-picker dependencies on the shared [sl] service locator.
///
/// Idempotent — calling [init] more than once (e.g. across hot restarts) is a
/// no-op after the first registration.
///
/// The only public dependency features resolve is [AssetPickerService]; the
/// concrete providers stay internal. [AssetPickerConfig] is registered too so
/// the `AssetPicker` facade can build the UI theme from it.
abstract final class AssetPickerDI {
  AssetPickerDI._();

  static void init({AssetPickerConfig config = const AssetPickerConfig()}) {
    if (sl.isRegistered<AssetPickerService>()) return;

    sl
      ..registerSingleton<AssetPickerConfig>(config)
      ..registerLazySingleton<AssetPickerService>(
        () => AssetPickerServiceImpl(
          cameraProvider: config.registerCamera
              ? (config.cameraProvider ?? ImagePickerCameraProvider())
              : null,
          galleryProvider: config.registerGallery
              ? (config.galleryProvider ?? ImagePickerGalleryProvider())
              : null,
          fileProvider: config.registerFiles
              ? (config.fileProvider ?? const FilePickerFileProvider())
              : null,
          scannerProvider: config.registerScanner
              ? (config.scannerProvider ?? _defaultScannerProvider(config))
              : null,
          validator: config.validator,
        ),
      );
  }

  /// Picks the default scanner: the real `document_camera_frame` scanner when a
  /// [AssetPickerConfig.scannerNavigatorKey] is supplied, otherwise the
  /// zero-config camera fallback.
  static ScannerProvider _defaultScannerProvider(AssetPickerConfig config) {
    final navigatorKey = config.scannerNavigatorKey;
    if (navigatorKey != null) {
      return DocumentCameraFrameScannerProvider(
        navigatorKey: navigatorKey,
        config: config.documentScannerConfig,
      );
    }
    return DocumentCameraScannerProvider();
  }
}
