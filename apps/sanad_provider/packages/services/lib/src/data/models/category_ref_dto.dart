import 'package:core/core.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';

class CategoryRefDto extends CategoryRefEntity
    implements EntityConverter<CategoryRefEntity> {
  const CategoryRefDto({
    required super.id,
    required super.name,
    required super.description,
  });

  factory CategoryRefDto.fromJson(Map<String, dynamic> json) => CategoryRefDto(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
  );

  @override
  CategoryRefEntity toEntity() =>
      CategoryRefEntity(id: id, name: name, description: description);
}
