import 'package:organization_settings/src/domain/entities/media_entity.dart';

/// Mirrors `LegalDataMediaResponseDto` exactly.
///
/// Structurally identical to [ServiceProviderMediaResponse] — kept as a
/// separate DTO because the backend models them as distinct schemas
/// (`LegalDataMediaResponseDto` vs `ServiceProviderMediaResponseDto`); both
/// map onto the shared [MediaEntity] domain type.
class LegalDataMediaResponse {
  const LegalDataMediaResponse({
    required this.id,
    required this.url,
    required this.originalName,
    required this.mimeType,
  });

  factory LegalDataMediaResponse.fromJson(Map<String, dynamic> json) {
    return LegalDataMediaResponse(
      id: json['id'] as String,
      url: json['url'] as String,
      originalName: json['originalName'] as String,
      mimeType: json['mimeType'] as String,
    );
  }

  final String id;
  final String url;
  final String originalName;
  final String mimeType;

  MediaEntity toEntity() => MediaEntity(
    id: id,
    url: url,
    originalName: originalName,
    mimeType: mimeType,
  );
}
