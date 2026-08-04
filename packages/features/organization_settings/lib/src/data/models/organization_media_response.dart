import 'package:organization_settings/src/domain/entities/organization_media_entity.dart';

/// Tolerant DTO for the organization media upload response — unwraps a `data`
/// envelope and matches common id/url field aliases.
class OrganizationMediaResponse {
  const OrganizationMediaResponse({this.id, this.url});

  factory OrganizationMediaResponse.fromJson(Map<String, dynamic> json) {
    final map = _unwrap(json);
    return OrganizationMediaResponse(
      id: _firstString(map, const ['id', 'mediaId', '_id']),
      url: _firstString(map, const ['url', 'mediaUrl', 'path', 'location']),
    );
  }

  final String? id;
  final String? url;

  OrganizationMediaEntity toEntity() =>
      OrganizationMediaEntity(id: id, url: url);

  static Map<String, dynamic> _unwrap(Map<String, dynamic> raw) {
    final data = raw['data'];
    if (data is Map<String, dynamic>) return data;
    return raw;
  }

  static String? _firstString(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.isNotEmpty) return value;
    }
    return null;
  }
}
