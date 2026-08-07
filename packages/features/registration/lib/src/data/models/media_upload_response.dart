import 'package:document_flow/document_flow.dart';

/// DTO for `POST media/onboarding`.
class MediaUploadResponse {
  const MediaUploadResponse({
    required this.id,
    required this.originalName,
    required this.fileName,
    required this.mimeType,
    required this.size,
    required this.backendType,
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
        backendType: json['type'] as String? ?? '',
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

  /// The document category as classified by the backend — unrelated to the
  /// [DocumentType] slot the caller uploaded to.
  final String backendType;
  final String url;
  final DateTime createdAt;

  /// Maps to the generic [DocumentMedia], tagged with the [type] slot the
  /// caller uploaded to (the backend's own category isn't carried forward).
  DocumentMedia toEntity({required DocumentType type}) => DocumentMedia(
    id: id,
    fileName: fileName,
    mimeType: mimeType,
    size: size,
    url: url,
    type: type,
  );
}
