import 'dart:typed_data';

import 'package:asset_picker/src/domain/enums/asset_type.dart';
import 'package:equatable/equatable.dart';

/// An immutable, plugin-agnostic representation of a single acquired asset.
///
/// This is the *only* asset shape the application ever sees. Whether the file
/// came from `image_picker`, `file_picker`, a document scanner, or a future
/// cloud provider, it is normalised into a [PickedAsset] before it crosses the
/// package boundary.
class PickedAsset extends Equatable {
  const PickedAsset({
    required this.name,
    required this.path,
    required this.mimeType,
    required this.size,
    required this.assetType,
    this.bytes,
  });

  /// The file name including its extension (e.g. `receipt.pdf`).
  final String name;

  /// Absolute path to the file on the device file system.
  ///
  /// May be empty for assets that only exist in memory (e.g. some web or
  /// clipboard sources) — in that case [bytes] is guaranteed to be non-null.
  final String path;

  /// The in-memory bytes of the asset.
  ///
  /// Optional: providers only populate this when the caller requested it
  /// (`AssetPickerOptions.loadBytes`) or when the platform has no file path.
  final Uint8List? bytes;

  /// The MIME type (e.g. `image/jpeg`, `application/pdf`). Best-effort — falls
  /// back to `application/octet-stream` when the platform cannot determine it.
  final String mimeType;

  /// File size in bytes.
  final int size;

  /// The logical [AssetType] this asset was classified as.
  final AssetType assetType;

  /// The lower-cased file extension without a leading dot (e.g. `pdf`), derived
  /// from [name]. Empty when the name has no extension.
  String get extension {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) return '';
    return name.substring(dot + 1).toLowerCase();
  }

  /// Size expressed in kilobytes (1 KB = 1024 bytes).
  double get sizeInKb => size / 1024;

  /// Size expressed in megabytes (1 MB = 1024 KB).
  double get sizeInMb => sizeInKb / 1024;

  /// Whether the raw [bytes] are available in memory.
  bool get hasBytes => bytes != null;

  /// Returns a copy with selected fields overridden.
  PickedAsset copyWith({
    String? name,
    String? path,
    Uint8List? bytes,
    String? mimeType,
    int? size,
    AssetType? assetType,
  }) {
    return PickedAsset(
      name: name ?? this.name,
      path: path ?? this.path,
      bytes: bytes ?? this.bytes,
      mimeType: mimeType ?? this.mimeType,
      size: size ?? this.size,
      assetType: assetType ?? this.assetType,
    );
  }

  @override
  List<Object?> get props => [name, path, bytes, mimeType, size, assetType];

  @override
  String toString() =>
      'PickedAsset(name: $name, mimeType: $mimeType, size: $size, '
      'assetType: $assetType, hasBytes: $hasBytes)';
}
