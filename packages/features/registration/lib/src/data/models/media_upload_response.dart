import 'package:registration/src/domain/entities/media_file_entity.dart';

/// DTO for `POST media/upload-single`.
class MediaUploadResponse {
  const MediaUploadResponse({
    required this.id,
    required this.originalName,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.type,
    required this.url,
    required this.createdAt,
  });

  factory MediaUploadResponse.fromJson(Map<String, dynamic> json) =>
      MediaUploadResponse(
        id: json['id'] as String,
        originalName: json['originalName'] as String? ?? '',
        fileName: json['fileName'] as String? ?? '',
        mimeType: json['mimeType'] as String? ?? '',
        size: (json['size'] as num?)?.toInt() ?? 0,
        type: json['type'] as String? ?? '',
        url: json['url'] as String? ?? '',
        createdAt: DateTime.parse(
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
        ),
      );

  final String id;
  final String originalName;
  final String fileName;
  final String mimeType;
  final int size;
  final String type;
  final String url;
  final DateTime createdAt;

  MediaFileEntity toEntity() => MediaFileEntity(
        id: id,
        originalName: originalName,
        fileName: fileName,
        mimeType: mimeType,
        size: size,
        type: type,
        url: url,
        createdAt: createdAt,
      );
}
