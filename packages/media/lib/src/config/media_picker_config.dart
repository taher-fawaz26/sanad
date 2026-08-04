import 'package:asset_picker/asset_picker.dart';
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
    this.maxFileSize = 10 * 1024 * 1024,
  });

  /// Which media kinds are accepted. Image-only today.
  final List<MediaType> allowedTypes;

  /// Accepted file extensions (bare, case-insensitive).
  final List<String> allowedExtensions;

  /// Maximum accepted source file size in bytes.
  final int maxFileSize;

  bool get imageOnly =>
      allowedTypes.length == 1 && allowedTypes.first.isImage;

  /// Builds the `asset_picker` options for a single source pick. [loadBytes]
  /// is forced on so the editor/processor always has in-memory bytes.
  AssetPickerOptions toAssetPickerOptions() => AssetPickerOptions(
    allowedAssetTypes: [
      for (final type in allowedTypes)
        if (type.isImage) AssetType.image else AssetType.video,
    ],
    allowedExtensions: allowedExtensions,
    maxFileSize: maxFileSize,
    loadBytes: true,
  );

  @override
  List<Object?> get props => [allowedTypes, allowedExtensions, maxFileSize];
}
