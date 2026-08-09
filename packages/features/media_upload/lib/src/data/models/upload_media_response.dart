import 'package:media_upload/src/domain/entities/uploaded_media.dart';

/// Wire model for `POST /media/upload-single`'s response body.
class UploadMediaResponse {
  const UploadMediaResponse({
    required this.id,
    required this.originalName,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.url,
    this.type,
    this.createdAt,
  });

  factory UploadMediaResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return UploadMediaResponse(
      id: map['id'] as String,
      originalName: map['originalName'] as String? ?? '',
      fileName: map['fileName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      url: map['url'] as String? ?? '',
      type: map['type'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? ''),
    );
  }

  final String id;
  final String originalName;
  final String fileName;
  final String mimeType;
  final int size;
  final String url;
  final String? type;
  final DateTime? createdAt;

  UploadedMedia toEntity() => UploadedMedia(
    mediaId: id,
    url: url,
    originalName: originalName,
    fileName: fileName,
    mimeType: mimeType,
    size: size,
    type: type,
    createdAt: createdAt,
  );

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }
}
