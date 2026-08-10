import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/service_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';

/// `ServiceResponseDto` — a provider's own service, returned by the real
/// services CRUD endpoints (`POST/GET/PATCH/DELETE /services`).
///
/// Deliberately a separate type from the pre-existing `ServiceEntity`, which
/// is a distinct, narrower shape (`{id, name, category}`) already used by the
/// `branches` package for an unrelated branch-service-assignment catalog —
/// that type and its endpoint are out of scope and must not change.
class ServiceRecordEntity extends Equatable {
  const ServiceRecordEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isActive,
    required this.category,
    required this.media,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final num price;
  final bool isActive;
  final ServiceCategorySummaryEntity category;
  final List<ServiceMediaEntity> media;
  final DateTime createdAt;
  final DateTime updatedAt;

  ServiceRecordEntity copyWith({bool? isActive}) => ServiceRecordEntity(
    id: id,
    name: name,
    description: description,
    price: price,
    isActive: isActive ?? this.isActive,
    category: category,
    media: media,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    price,
    isActive,
    category,
    media,
    createdAt,
    updatedAt,
  ];
}
