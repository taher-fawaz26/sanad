import 'package:core/core.dart';
import 'package:services/src/data/models/category_ref_dto.dart';
import 'package:services/src/data/models/provider_service_image_dto.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_image_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';

class ProviderServiceDto extends ProviderServiceEntity
    implements EntityConverter<ProviderServiceEntity> {
  const ProviderServiceDto({
    required super.id,
    required super.serviceId,
    required super.serviceName,
    required super.category,
    required super.description,
    required super.status,
    required super.images,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ProviderServiceDto.fromJson(Map<String, dynamic> json) {
    final service = json['service'] as Map<String, dynamic>?;
    // `GET /provider-services` list rows carry only `primaryImage`, not a
    // full `images` array (the full set is on the detail endpoint) — fall
    // back to wrapping it as a single-item list so `primaryImage` still
    // resolves for the dashboard cards.
    final imagesJson = json['images'] as List<dynamic>?;
    final images = imagesJson != null
        ? imagesJson
              .whereType<Map<String, dynamic>>()
              .map(ProviderServiceImageDto.fromJson)
              .toList()
        : [
            if (json['primaryImage'] != null)
              ProviderServiceImageDto.fromJson(
                json['primaryImage'] as Map<String, dynamic>,
              ),
          ];
    // `category` is nested under `service` on the create/detail response
    // shape (`{id, service: {id, name, category}, ...}`); some list rows
    // may instead return it flattened at the top level — support both.
    final categoryJson =
        (json['category'] ?? service?['category']) as Map<String, dynamic>;
    return ProviderServiceDto(
      id: json['id'] as String,
      serviceId: (service?['id'] ?? json['serviceId']) as String,
      serviceName: (service?['name'] ?? json['serviceName']) as String,
      category: CategoryRefDto.fromJson(categoryJson),
      description: json['description'] as String?,
      status: ProviderServiceStatus.fromApi(json['status'] as String),
      images: images,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  ProviderServiceEntity toEntity() => ProviderServiceEntity(
    id: id,
    serviceId: serviceId,
    serviceName: serviceName,
    category: CategoryRefEntity(
      id: category.id,
      name: category.name,
      description: category.description,
    ),
    description: description,
    status: status,
    images: images
        .map(
          (i) => ProviderServiceImageEntity(
            id: i.id,
            mediaId: i.mediaId,
            url: i.url,
            isPrimary: i.isPrimary,
          ),
        )
        .toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
