import 'package:equatable/equatable.dart';

/// A catalogue service the client can request.
///
/// `name` is localized server-side from the `x-lang` header, so it is rendered
/// verbatim and never passed through `.tr()`.
class CatalogueService extends Equatable {
  /// Creates a catalogue service.
  const CatalogueService({
    required this.id,
    required this.name,
    this.categoryId,
    this.categoryName,
    this.imageUrl,
  });

  /// Catalogue service id — what a draft stores as `serviceId`.
  final String id;

  /// Display name, already localized by the server.
  final String name;

  /// Owning category id, when the server resolves one.
  final String? categoryId;

  /// Owning category display name.
  final String? categoryName;

  /// Optional illustration.
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, categoryId, categoryName, imageUrl];
}

/// A catalogue category, for grouping the service picker.
class CatalogueCategory extends Equatable {
  /// Creates a catalogue category.
  const CatalogueCategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  /// Category id.
  final String id;

  /// Display name, already localized by the server.
  final String name;

  /// Optional illustration.
  final String? imageUrl;

  @override
  List<Object?> get props => [id, name, imageUrl];
}
