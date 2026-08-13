import 'package:equatable/equatable.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';

/// A provider's own offered service (`GET/POST/PATCH/DELETE
/// /provider-services`). References a catalog service by [serviceId]
/// (immutable after creation) and carries the provider's own
/// [description] + [images]. There is no price on this contract.
class ProviderServiceEntity extends Equatable {
  const ProviderServiceEntity({
    required this.id,
    required this.serviceId,
    required this.serviceName,
    required this.category,
    required this.description,
    required this.status,
    required this.images,
    required this.createdAt,
    required this.updatedAt,
    this.requests = 0,
    this.revenue = 0,
  });

  final String id;
  final String serviceId;
  final String serviceName;
  final CategoryRefEntity category;
  final String? description;
  final ProviderServiceStatus status;
  final List<ProviderServiceImageEntity> images;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Total service requests received — only populated by the by-id detail
  /// endpoint (`GET /provider-services/{id}`); defaults to `0` elsewhere
  /// (list rows, skeletons) where the backend doesn't return it.
  final int requests;

  /// Total revenue generated — same by-id-only availability as [requests].
  final num revenue;

  ProviderServiceImageEntity? get primaryImage {
    for (final image in images) {
      if (image.isPrimary) return image;
    }
    return images.isEmpty ? null : images.first;
  }

  ProviderServiceEntity copyWith({
    String? description,
    ProviderServiceStatus? status,
    List<ProviderServiceImageEntity>? images,
  }) => ProviderServiceEntity(
    id: id,
    serviceId: serviceId,
    serviceName: serviceName,
    category: category,
    description: description ?? this.description,
    status: status ?? this.status,
    images: images ?? this.images,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  @override
  List<Object?> get props => [
    id,
    serviceId,
    serviceName,
    category,
    description,
    status,
    images,
    createdAt,
    updatedAt,
    requests,
    revenue,
  ];
}
