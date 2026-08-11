import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';

/// `ServiceCategorySummaryDto` — the category summary embedded on a
/// [ServiceRecordEntity]. `icon` is nullable but the key is always present.
class ServiceCategorySummaryEntity extends Equatable {
  const ServiceCategorySummaryEntity({
    required this.id,
    required this.name,
    required this.slug,
    required this.icon,
  });

  final String id;
  final String name;
  final String slug;
  final ServiceMediaEntity? icon;

  @override
  List<Object?> get props => [id, name, slug, icon];
}
