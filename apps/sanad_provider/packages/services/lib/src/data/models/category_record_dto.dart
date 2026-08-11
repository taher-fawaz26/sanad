import 'package:core/core.dart';
import 'package:services/src/data/models/category_icon_dto.dart';
import 'package:services/src/domain/entities/category_icon_entity.dart';
import 'package:services/src/domain/entities/category_record_entity.dart';

class CategoryRecordDto extends CategoryRecordEntity
    implements EntityConverter<CategoryRecordEntity> {
  const CategoryRecordDto({
    required super.id,
    required super.slug,
    required super.name,
    required super.description,
    required super.icon,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CategoryRecordDto.fromJson(Map<String, dynamic> json) {
    final iconJson = json['icon'] as Map<String, dynamic>?;
    return CategoryRecordDto(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: iconJson == null ? null : CategoryIconDto.fromJson(iconJson),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  CategoryRecordEntity toEntity() => CategoryRecordEntity(
    id: id,
    slug: slug,
    name: name,
    description: description,
    icon: icon == null
        ? null
        : CategoryIconEntity(id: icon!.id, url: icon!.url),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
