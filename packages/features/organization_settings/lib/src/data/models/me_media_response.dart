import 'package:organization_settings/src/domain/entities/me_media_entity.dart';

/// Mirrors `MeMediaDto` exactly (`{id, url}`) — what `GET /settings` actually
/// sends for `businessProfile.coverImage`/`.profileImage`.
///
/// Not to be confused with [ServiceProviderMediaResponse], which was written
/// against a `originalName`/`mimeType`-bearing shape that `GET /settings`
/// never sends for these two fields.
class MeMediaResponse {
  const MeMediaResponse({required this.id, required this.url});

  factory MeMediaResponse.fromJson(Map<String, dynamic> json) {
    return MeMediaResponse(
      id: json['id'] as String,
      url: json['url'] as String,
    );
  }

  final String id;
  final String url;

  MeMediaEntity toEntity() => MeMediaEntity(id: id, url: url);
}
