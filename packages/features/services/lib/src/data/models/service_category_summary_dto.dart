import 'package:core/core.dart';
import 'package:services/src/data/models/service_media_dto.dart';
import 'package:services/src/domain/entities/service_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';

class ServiceCategorySummaryDto extends ServiceCategorySummaryEntity
    implements EntityConverter<ServiceCategorySummaryEntity> {
  const ServiceCategorySummaryDto({
    required super.id,
    required super.name,
    required super.slug,
    required super.icon,
  });

  factory ServiceCategorySummaryDto.fromJson(Map<String, dynamic> json) {
    final iconJson = json['icon'] as Map<String, dynamic>?;
    return ServiceCategorySummaryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      icon: iconJson == null ? null : ServiceMediaDto.fromJson(iconJson),
    );
  }

  @override
  ServiceCategorySummaryEntity toEntity() => ServiceCategorySummaryEntity(
    id: id,
    name: name,
    slug: slug,
    icon: icon == null
        ? null
        : ServiceMediaEntity(id: icon!.id, url: icon!.url, type: icon!.type),
  );
}
