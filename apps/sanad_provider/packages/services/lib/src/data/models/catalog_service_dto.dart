import 'package:core/core.dart';
import 'package:services/src/data/models/category_ref_dto.dart';
import 'package:services/src/domain/entities/catalog_service_entity.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';

class CatalogServiceDto extends CatalogServiceEntity
    implements EntityConverter<CatalogServiceEntity> {
  const CatalogServiceDto({
    required super.id,
    required super.name,
    required super.category,
  });

  factory CatalogServiceDto.fromJson(Map<String, dynamic> json) =>
      CatalogServiceDto(
        id: json['id'] as String,
        name: json['name'] as String,
        category: CategoryRefDto.fromJson(
          json['category'] as Map<String, dynamic>,
        ),
      );

  @override
  CatalogServiceEntity toEntity() => CatalogServiceEntity(
    id: id,
    name: name,
    category: CategoryRefEntity(
      id: category.id,
      name: category.name,
      description: category.description,
    ),
  );
}
