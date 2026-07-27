import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/validation/asset_validator.dart';
import 'package:asset_picker/src/infrastructure/providers/camera_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/file_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/gallery_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/scanner_provider.dart';
import 'package:asset_picker/src/infrastructure/scanner/document_scanner_config.dart';
import 'package:asset_picker/src/theme/asset_picker_theme.dart';
import 'package:flutter/widgets.dart';

/// The composition-root configuration for the asset picker.
///
/// This is where an application (or a test) injects everything that varies:
/// which provider implementation backs each source, the validator, the default
/// options, and the UI theme. Passing a `const AssetPickerConfig()` gives the
/// batteries-included defaults (image_picker + file_picker + camera scanner).
///
/// Nothing here references a business feature — the config is purely about
/// *how assets are acquired and presented*.
@immutable
class AssetPickerConfig {
  const AssetPickerConfig({
    this.cameraProvider,
    this.galleryProvider,
    this.fileProvider,
    this.scannerProvider,
    this.validator = const DefaultAssetValidator(),
    this.defaultOptions = const AssetPickerOptions(),
    this.themeBuilder,
    this.colors,
    this.texts,
    this.icons,
    this.scannerNavigatorKey,
    this.documentScannerConfig = const DocumentScannerConfig(),
    this.registerCamera = true,
    this.registerGallery = true,
    this.registerFiles = true,
    this.registerScanner = true,
  });

  /// Override the camera implementation. `null` uses the default
  /// (`ImagePickerCameraProvider`).
  final CameraProvider? cameraProvider;

  /// Override the gallery implementation. `null` uses the default
  /// (`ImagePickerGalleryProvider`).
  final GalleryProvider? galleryProvider;

  /// Override the file implementation. `null` uses the default
  /// (`FilePickerFileProvider`).
  final FileProvider? fileProvider;

  /// Override the scanner implementation. `null` uses the default
  /// (`DocumentCameraScannerProvider`). Drop in `document_camera_frame` /
  /// `flutter_doc_scanner` here without touching feature code.
  final ScannerProvider? scannerProvider;

  /// The validator applied to every selection. Defaults to
  /// [DefaultAssetValidator]; supply a custom one to add business rules.
  final AssetValidator validator;

  /// The options used when a caller does not pass its own.
  final AssetPickerOptions defaultOptions;

  /// Full override for theme resolution. When set, it wins over
  /// [colors]/[texts]/[icons].
  final AssetPickerTheme Function(BuildContext context)? themeBuilder;

  /// Partial theme override — colors.
  final AssetPickerColors? colors;

  /// Partial theme override — copy.
  final AssetPickerTexts? texts;

  /// Partial theme override — icons.
  final AssetPickerIcons? icons;

  /// A key to the app's root navigator, used to present the real
  /// `document_camera_frame` scanner (edge detection, perspective correction,
  /// cropping, JPEG output).
  ///
  /// When provided (and no explicit [scannerProvider] is set), the picker uses
  /// the real document scanner instead of the camera fallback. It is a key
  /// (not a `BuildContext`) so the context-free `ScannerProvider.scan` contract
  /// stays unchanged. Leave `null` to keep the zero-config camera fallback.
  final GlobalKey<NavigatorState>? scannerNavigatorKey;

  /// Tuning for the document-scanner presentation. Plugin-agnostic.
  final DocumentScannerConfig documentScannerConfig;

  /// Whether to register each provider. Set to `false` to leave a source
  /// unavailable — attempting to use it then throws
  /// `AssetSourceUnavailableException`.
  final bool registerCamera;
  final bool registerGallery;
  final bool registerFiles;
  final bool registerScanner;

  /// Resolves the theme for [context], honouring [themeBuilder] then the
  /// partial group overrides, then the design-system defaults.
  AssetPickerTheme resolveTheme(BuildContext context) {
    final builder = themeBuilder;
    if (builder != null) return builder(context);
    return AssetPickerTheme.of(
      context,
      colors: colors,
      texts: texts,
      icons: icons,
    );
  }
}
