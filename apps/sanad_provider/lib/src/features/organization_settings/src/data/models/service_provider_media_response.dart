import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/media_entity.dart';

/// Mirrors `ServiceProviderMediaResponseDto` exactly.
class ServiceProviderMediaResponse {
  const ServiceProviderMediaResponse({
    required this.id,
    required this.url,
    required this.originalName,
    required this.mimeType,
  });

  factory ServiceProviderMediaResponse.fromJson(Map<String, dynamic> json) {
    return ServiceProviderMediaResponse(
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
