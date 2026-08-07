import 'package:organization_settings/src/domain/entities/category_entity.dart';

/// Mirrors `ServiceProviderCategoryResponseDto` exactly.
class ServiceProviderCategoryResponse {
  const ServiceProviderCategoryResponse({
    required this.id,
    required this.name,
  });

  factory ServiceProviderCategoryResponse.fromJson(Map<String, dynamic> json) {
    return ServiceProviderCategoryResponse(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  final String id;
  final String name;

  CategoryEntity toEntity() => CategoryEntity(id: id, name: name);
}
