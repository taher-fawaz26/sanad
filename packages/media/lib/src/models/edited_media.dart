import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:media/src/models/media_source.dart';
import 'package:media/src/models/media_type.dart';

/// The output of the media toolkit — a fully processed image ready to be
/// handed to a consuming feature for upload.
///
/// This is intentionally rich (dimensions, mime, size, source) so features
/// never have to re-decode the bytes to learn about them. The package's
/// responsibility ends here: what happens next (upload, retry, cancel) is the
/// feature's concern.
class EditedMedia extends Equatable {
  const EditedMedia({
    required this.bytes,
    required this.width,
    required this.height,
    required this.mimeType,
    required this.fileName,
    required this.fileSize,
    required this.source,
    this.mediaType = MediaType.image,
  });

  /// The final, processed bytes (cropped, oriented, resized, compressed).
  final Uint8List bytes;

  /// Pixel dimensions of [bytes] after processing.
  final int width;
  final int height;

  /// MIME type of the encoded output (e.g. `image/jpeg`, `image/png`).
  final String mimeType;

  /// A suggested file name including extension (e.g. `avatar.jpg`).
  final String fileName;

  /// Byte length of [bytes].
  final int fileSize;

  /// Where the original asset was acquired from.
  final MediaSource? source;

  /// The high-level media kind. Always [MediaType.image] today.
  final MediaType mediaType;

  double get sizeInKb => fileSize / 1024;

  double get sizeInMb => sizeInKb / 1024;

  @override
  List<Object?> get props => [
    bytes,
    width,
    height,
    mimeType,
    fileName,
    fileSize,
    source,
    mediaType,
  ];

  @override
  String toString() =>
      'EditedMedia($fileName, ${width}x$height, $mimeType, '
      '${sizeInKb.toStringAsFixed(1)}KB, source: $source)';
}
