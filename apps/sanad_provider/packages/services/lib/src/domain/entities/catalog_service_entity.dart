import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';

/// A row from the master catalog (`GET /services`) — read-only, browsable,
/// active-only. Providers pick a [CatalogServiceEntity.id] to offer via
/// `POST /provider-services`; they cannot create catalog services.
class CatalogServiceEntity extends Equatable {
  const CatalogServiceEntity({
    required this.id,
    required this.name,
    required this.category,
  });

  final String id;

  /// Canonical service name — deliberately never translated by the backend
  /// (unlike [category], whose `name`/`description` are localized). Do not
  /// attempt to translate this client-side; render it as-is regardless of
  /// app language.
  final String name;
  final CategoryRefEntity category;

  @override
  List<Object?> get props => [id, name, category];
}
