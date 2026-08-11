import 'package:core/core.dart';
import 'package:services/src/data/models/service_category_summary_dto.dart';
import 'package:services/src/data/models/service_media_dto.dart';
import 'package:services/src/domain/entities/service_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';

class ServiceRecordDto extends ServiceRecordEntity
    implements EntityConverter<ServiceRecordEntity> {
  const ServiceRecordDto({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.isActive,
    required super.category,
    required super.media,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ServiceRecordDto.fromJson(Map<String, dynamic> json) {
    final media = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ServiceMediaDto.fromJson)
        .toList();
    return ServiceRecordDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      price: json['price'] as num,
      isActive: json['isActive'] as bool,
      category: ServiceCategorySummaryDto.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      media: media,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  ServiceRecordEntity toEntity() => ServiceRecordEntity(
    id: id,
    name: name,
    description: description,
    price: price,
    isActive: isActive,
    category: ServiceCategorySummaryEntity(
      id: category.id,
      name: category.name,
      slug: category.slug,
      icon: category.icon == null
          ? null
          : ServiceMediaEntity(
              id: category.icon!.id,
              url: category.icon!.url,
              type: category.icon!.type,
            ),
    ),
    media: media
        .map((m) => ServiceMediaEntity(id: m.id, url: m.url, type: m.type))
        .toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
