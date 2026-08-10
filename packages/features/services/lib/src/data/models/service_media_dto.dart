import 'package:core/core.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';

class ServiceMediaDto extends ServiceMediaEntity
    implements EntityConverter<ServiceMediaEntity> {
  const ServiceMediaDto({
    required super.id,
    required super.url,
    required super.type,
  });

  factory ServiceMediaDto.fromJson(Map<String, dynamic> json) =>
      ServiceMediaDto(
        id: json['id'] as String,
        url: json['url'] as String,
        type: json['type'] as String,
      );

  @override
  ServiceMediaEntity toEntity() =>
      ServiceMediaEntity(id: id, url: url, type: type);
}
