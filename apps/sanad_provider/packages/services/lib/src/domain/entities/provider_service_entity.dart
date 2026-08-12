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
  ];
}
