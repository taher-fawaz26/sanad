import 'package:equatable/equatable.dart';

/// Lightweight catalog-service shape handed to consumers outside the
/// services package (e.g. `branches`' service-assignment picker) so they
/// never see provider-service internals.
class CatalogServiceSelection extends Equatable {
  const CatalogServiceSelection({
    required this.id,
    required this.name,
    required this.categoryName,
  });

  final String id;
  final String name;
  final String categoryName;

  @override
  List<Object?> get props => [id, name, categoryName];
}
