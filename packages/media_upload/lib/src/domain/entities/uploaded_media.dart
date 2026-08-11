import 'package:equatable/equatable.dart';

/// The backend's record of a successfully uploaded file.
///
/// [mediaId] is mandatory and must be preserved by every caller — features
/// use it for their own attach/replace operations (e.g.
/// `PATCH /service-provider/profile-image`). [url] is display-only; business
/// logic must never treat it as the identifier.
class UploadedMedia extends Equatable {
  const UploadedMedia({
    required this.mediaId,
    required this.url,
    required this.originalName,
    required this.fileName,
    required this.mimeType,
    required this.size,
    this.type,
    this.createdAt,
  });

  /// Backend identifier — mandatory, used for later attach/replace calls.
  final String mediaId;

  final String url;
  final String originalName;
  final String fileName;
  final String mimeType;
  final int size;
  final String? type;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [
    mediaId,
    url,
    originalName,
    fileName,
    mimeType,
    size,
    type,
    createdAt,
  ];

  @override
  String toString() =>
      'UploadedMedia(mediaId: $mediaId, url: $url, fileName: $fileName)';
}
