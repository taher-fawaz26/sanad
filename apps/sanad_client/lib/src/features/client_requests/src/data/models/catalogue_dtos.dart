import 'package:sanad_client/src/features/client_requests/src/domain/entities/catalogue_entities.dart';

/// A catalogue service row.
///
/// The catalogue endpoint has grown several shapes over time (a flat
/// `categoryId`/`categoryName` pair, or a nested `category` object), so both
/// are read. `name` arrives already localized from `x-lang`.
class CatalogueServiceDto {
  /// Creates a DTO.
  const CatalogueServiceDto({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  /// Reads the server payload, accepting either the flat category pair
  /// or the nested `category` object.
  factory CatalogueServiceDto.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    final nested = category is Map
        ? Map<String, dynamic>.from(category)
        : const <String, dynamic>{};
    return CatalogueServiceDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? nested['id'] as String?,
      categoryName:
          json['categoryName'] as String? ?? nested['name'] as String?,
      imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
    );
  }

  /// Catalogue service id.
  final String id;

  /// Display name, already localized by the server.
  final String name;

  /// Owning category id.
  final String? categoryId;

  /// Owning category display name.
  final String? categoryName;

  /// Optional illustration.
  final String? imageUrl;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'categoryId': categoryId,
    'categoryName': categoryName,
    'imageUrl': imageUrl,
  };

  /// Converts to the domain entity.
  CatalogueService toEntity() => CatalogueService(
    id: id,
    name: name,
    categoryId: categoryId,
    categoryName: categoryName,
    imageUrl: imageUrl,
  );
}

/// A catalogue category row.
class CatalogueCategoryDto {
  /// Creates a DTO.
  const CatalogueCategoryDto({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  /// Reads the server payload.
  factory CatalogueCategoryDto.fromJson(Map<String, dynamic> json) =>
      CatalogueCategoryDto(
        id: json['id'] as String? ?? '',
        name: json['name'] as String? ?? '',
        imageUrl: json['imageUrl'] as String? ?? json['image'] as String?,
      );

  /// Category id.
  final String id;

  /// Display name, already localized by the server.
  final String name;

  /// Optional illustration.
  final String? imageUrl;

  /// Serializes back to the wire shape.
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'imageUrl': imageUrl,
  };

  /// Converts to the domain entity.
  CatalogueCategory toEntity() =>
      CatalogueCategory(id: id, name: name, imageUrl: imageUrl);
}
