import 'package:asset_picker/src/domain/entities/asset_picker_options.dart';
import 'package:asset_picker/src/domain/entities/picked_asset.dart';
import 'package:asset_picker/src/domain/enums/asset_source.dart';
import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:asset_picker/src/domain/failures/asset_picker_exception.dart';
import 'package:asset_picker/src/infrastructure/providers/camera_provider.dart';
import 'package:asset_picker/src/infrastructure/providers/gallery_provider.dart';
import 'package:asset_picker/src/utils/asset_mime_resolver.dart';
import 'package:flutter/services.dart' show PlatformException;
import 'package:image_picker/image_picker.dart';

/// Maps an `image_picker` [XFile] into a plugin-agnostic [PickedAsset].
///
/// Shared by the camera and gallery providers so the mapping (and its error
/// handling) lives in exactly one place.
Future<PickedAsset> _toPickedAsset(
  XFile file, {
  required bool loadBytes,
}) async {
  final size = await file.length();
  final mimeType = file.mimeType ?? AssetMimeResolver.fromFileName(file.name);
  return PickedAsset(
    name: file.name,
    path: file.path,
    bytes: loadBytes ? await file.readAsBytes() : null,
    mimeType: mimeType,
    size: size,
    assetType: AssetType.fromMimeType(mimeType),
  );
}

/// Translates an `image_picker` [PlatformException] into the package's own
/// exception vocabulary so callers never catch plugin types.
Never _rethrowAsPickerException(
  AssetSource source,
  PlatformException error,
) {
  final code = error.code.toLowerCase();
  if (code.contains('access_denied') || code.contains('permission')) {
    throw AssetPermissionDeniedException(
      source,
      permanentlyDenied: true,
      message: error.message ?? 'Access denied for $source.',
    );
  }
  throw AssetPickerPlatformException(
    error.message ?? 'The picker failed.',
    source: source,
    cause: error,
  );
}

/// [CameraProvider] backed by `image_picker`.
///
/// Photo capture today; video capture is future-ready (add a branch here when
/// `AssetType.video` capture is required — no interface change needed).
class ImagePickerCameraProvider implements CameraProvider {
  ImagePickerCameraProvider({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedAsset>> capture(AssetPickerOptions options) async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        // When compression is deferred to after validation, acquire the
        // untouched original so the validator gates on its true size.
        imageQuality: options.compressAtAcquisition
            ? options.imageQuality
            : null,
      );
      if (file == null) return const [];
      return [await _toPickedAsset(file, loadBytes: options.loadBytes)];
    } on PlatformException catch (e) {
      _rethrowAsPickerException(AssetSource.camera, e);
    }
  }
}

/// [GalleryProvider] backed by `image_picker`.
///
/// Supports single and multiple image selection. Video selection is
/// future-ready.
class ImagePickerGalleryProvider implements GalleryProvider {
  ImagePickerGalleryProvider({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  @override
  Future<List<PickedAsset>> pick(AssetPickerOptions options) async {
    try {
      // When compression is deferred to after validation, acquire untouched
      // originals so the validator gates on their true size.
      final quality = options.compressAtAcquisition
          ? options.imageQuality
          : null;
      if (options.allowMultiple) {
        final files = await _picker.pickMultiImage(imageQuality: quality);
        final limit = options.effectiveMaxSelection;
        final selected = files.length > limit ? files.sublist(0, limit) : files;
        return [
          for (final file in selected)
            await _toPickedAsset(file, loadBytes: options.loadBytes),
        ];
      }

      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: quality,
      );
      if (file == null) return const [];
      return [await _toPickedAsset(file, loadBytes: options.loadBytes)];
    } on PlatformException catch (e) {
      _rethrowAsPickerException(AssetSource.gallery, e);
    }
  }
}
