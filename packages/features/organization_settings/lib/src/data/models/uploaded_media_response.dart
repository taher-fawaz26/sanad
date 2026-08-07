/// Mirrors `UploadMediaResponse` — the shared `POST /media/upload-single`
/// response shape.
class UploadedMediaResponse {
  const UploadedMediaResponse({
    required this.id,
    required this.url,
    required this.originalName,
    required this.mimeType,
    required this.size,
  });

  factory UploadedMediaResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return UploadedMediaResponse(
      id: map['id'] as String,
      url: map['url'] as String,
      originalName: map['originalName'] as String? ?? '',
      mimeType: map['mimeType'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
    );
  }

  final String id;
  final String url;
  final String originalName;
  final String mimeType;
  final int size;

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }
}
