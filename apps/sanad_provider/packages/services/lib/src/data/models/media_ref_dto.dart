import 'package:core/core.dart';
import 'package:services/src/domain/entities/media_ref_entity.dart';

class MediaRefDto extends MediaRefEntity
    implements EntityConverter<MediaRefEntity> {
  const MediaRefDto({required super.id, required super.url});

  factory MediaRefDto.fromJson(Map<String, dynamic> json) =>
      MediaRefDto(id: json['id'] as String, url: json['url'] as String);

  @override
  MediaRefEntity toEntity() => MediaRefEntity(id: id, url: url);
}
