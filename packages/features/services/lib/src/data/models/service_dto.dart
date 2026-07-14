import 'package:core/core.dart';
import 'package:services/src/domain/entities/service_entity.dart';

class ServiceDto extends ServiceEntity implements EntityConverter<ServiceEntity> {
  const ServiceDto({
    required super.id,
    required super.name,
    required super.category,
  });

  factory ServiceDto.fromJson(Map<String, dynamic> json) => ServiceDto(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'category': category,
      };

  @override
  ServiceEntity toEntity() =>
      ServiceEntity(id: id, name: name, category: category);
}
