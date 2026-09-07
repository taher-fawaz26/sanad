import 'package:asset_picker/asset_picker.dart';
import 'package:core/core.dart';
import 'package:equatable/equatable.dart';
import 'package:media/src/models/media_type.dart';

/// Declarative configuration for the pick step.
///
/// Image-only by default (videos/unsupported files are rejected). Bridges to
/// an [AssetPickerOptions] via [toAssetPickerOptions] so the underlying
/// `asset_picker` stays the single acquisition implementation.
class MediaPickerConfig extends Equatable {
  const MediaPickerConfig({
    this.allowedTypes = const [MediaType.image],
    this.allowedExtensions = const ['jpg', 'jpeg', 'png', 'webp', 'heic'],
    this.maxFileSize = FileSizePolicy.maxBytes,
  });

  /// Which media kinds are accepted. Image-only today.
  final List<MediaType> allowedTypes;

  /// Accepted file extensions (bare, case-insensitive).
  final List<String> allowedExtensions;

  /// Maximum accepted source file size in bytes. Defaults to the app-wide
  /// `FileSizePolicy` maximum; [toAssetPickerOptions] forwards it into
  /// `AssetPickerOptions.maxFileSize`, which `DefaultAssetValidator` also
  /// clamps against that same global ceiling, so this can tighten it but
  /// never loosen it beyond the global maximum.
  final int maxFileSize;

  bool get imageOnly => allowedTypes.length == 1 && allowedTypes.first.isImage;

  /// Builds the `asset_picker` options for a single source pick. [loadBytes]
  /// is forced on so the editor/processor always has in-memory bytes.
  ///
  /// [AssetPickerOptions.enforceSizeBeforeCompression] is forced on so the
  /// size limit is validated against the *original* picked file, before any
  /// acquisition-time re-encoding shrinks an oversized image under the limit
  /// — otherwise a ~7 MB gallery/camera pick is silently accepted (SAN-781,
  /// same root cause as the services SAN-576 fix).
  AssetPickerOptions toAssetPickerOptions() => AssetPickerOptions(
    allowedAssetTypes: [
      for (final type in allowedTypes)
        if (type.isImage) AssetType.image else AssetType.video,
    ],
    allowedExtensions: allowedExtensions,
    maxFileSize: maxFileSize,
    loadBytes: true,
    enforceSizeBeforeCompression: true,
  );

  @override
  List<Object?> get props => [allowedTypes, allowedExtensions, maxFileSize];
}
