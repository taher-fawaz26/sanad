import 'package:core/core.dart';
import 'package:services/src/domain/entities/category_icon_entity.dart';

class CategoryIconDto extends CategoryIconEntity
    implements EntityConverter<CategoryIconEntity> {
  const CategoryIconDto({required super.id, required super.url});

  factory CategoryIconDto.fromJson(Map<String, dynamic> json) =>
      CategoryIconDto(id: json['id'] as String, url: json['url'] as String);

  @override
  CategoryIconEntity toEntity() => CategoryIconEntity(id: id, url: url);
}
