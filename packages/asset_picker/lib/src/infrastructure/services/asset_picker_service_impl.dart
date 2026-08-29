import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/asset_picker_result.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/failures/asset_picker_exception.dart';
import 'package:asset_picker/src/domain/services/asset_picker_service.dart';
import 'package:asset_picker/src/domain/validation/asset_validator.dart';
import 'package:asset_picker/src/infrastructure/compression/asset_image_compressor.dart';
import 'package:asset_picker/src/infrastructure/providers/camera_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/file_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/gallery_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/scanner_provider.dart';

/// The default [AssetPickerService] orchestrator.
///
/// Responsibilities (single, well-bounded):
/// 1. Route an [AssetSource] to its provider (dependency-inverted — providers
///    are injected, never constructed here).
/// 2. Normalise "user backed out" into [AssetPickerResult.cancelled].
/// 3. Validate the acquired selection against [AssetPickerOptions] and throw a
///    descriptive [AssetValidationException] on failure.
///
/// Any provider may be `null` (the corresponding source is simply
/// unavailable), which lets an app register only the sources it needs.
class AssetPickerServiceImpl implements AssetPickerService {
  const AssetPickerServiceImpl({
    CameraProvider? cameraProvider,
    GalleryProvider? galleryProvider,
    FileProvider? fileProvider,
    ScannerProvider? scannerProvider,
    AssetValidator validator = const DefaultAssetValidator(),
    AssetImageCompressor compressor = const ImagePackageAssetCompressor(),
  }) : _cameraProvider = cameraProvider,
       _galleryProvider = galleryProvider,
       _fileProvider = fileProvider,
       _scannerProvider = scannerProvider,
       _validator = validator,
       _compressor = compressor;

  final CameraProvider? _cameraProvider;
  final GalleryProvider? _galleryProvider;
  final FileProvider? _fileProvider;
  final ScannerProvider? _scannerProvider;
  final AssetValidator _validator;
  final AssetImageCompressor _compressor;

  @override
  Future<AssetPickerResult> pickFrom(
    AssetSource source, {
    AssetPickerOptions options = const AssetPickerOptions(),
  }) async {
    final assets = await _acquire(source, options);
    if (assets.isEmpty) return const AssetPickerResult.cancelled();

    // Validation runs on whatever the provider returned. With
    // `enforceSizeBeforeCompression`, that is the untouched original, so an
    // oversized file is rejected here — before the compression stage below can
    // shrink it under the limit.
    final errors = _validator.validate(assets, options);
    if (errors.isNotEmpty) throw AssetValidationException(errors);

    final delivered = options.compressAfterValidation
        ? await _compress(assets, options.imageQuality)
        : assets;

    return AssetPickerResult.success(assets: delivered, source: source);
  }

  /// Post-validation compression stage (see [AssetImageCompressor]). Only image
  /// assets are re-encoded; anything else passes through untouched.
  Future<List<PickedAsset>> _compress(
    List<PickedAsset> assets,
    int quality,
  ) async {
    final out = <PickedAsset>[];
    for (final asset in assets) {
      out.add(await _compressor.compress(asset, quality: quality));
    }
    return out;
  }

  @override
  Future<AssetPickerResult> pickCamera({
    AssetPickerOptions options = const AssetPickerOptions(),
  }) => pickFrom(AssetSource.camera, options: options);

  @override
  Future<AssetPickerResult> pickGallery({
    AssetPickerOptions options = const AssetPickerOptions(),
  }) => pickFrom(AssetSource.gallery, options: options);

  @override
  Future<AssetPickerResult> pickFile({
    AssetPickerOptions options = const AssetPickerOptions(),
  }) => pickFrom(AssetSource.files, options: options);

  @override
  Future<AssetPickerResult> scanDocument({
    AssetPickerOptions options = const AssetPickerOptions(),
  }) => pickFrom(AssetSource.scanner, options: options);

  Future<List<PickedAsset>> _acquire(
    AssetSource source,
    AssetPickerOptions options,
  ) {
    return switch (source) {
      AssetSource.camera => _require(_cameraProvider, source).capture(options),
      AssetSource.gallery => _require(_galleryProvider, source).pick(options),
      AssetSource.files => _require(_fileProvider, source).pick(options),
      AssetSource.scanner => _require(_scannerProvider, source).scan(options),
    };
  }

  T _require<T>(T? provider, AssetSource source) {
    if (provider == null) {
      throw AssetSourceUnavailableException(
        source,
        message:
            'No provider registered for $source. Register one via '
            'AssetPickerConfig before using this source.',
      );
    }
    return provider;
  }
}
