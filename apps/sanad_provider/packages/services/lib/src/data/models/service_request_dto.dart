import 'package:core/core.dart';
import 'package:services/src/data/models/category_ref_dto.dart';
import 'package:services/src/data/models/media_ref_dto.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/media_ref_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

/// Parses both the list row shape (`GET /service-requests`) and the detail
/// shape (`GET /service-requests/:id`, which adds `description`,
/// `rejectionReason`, `images`).
class ServiceRequestDto extends ServiceRequestEntity
    implements EntityConverter<ServiceRequestEntity> {
  const ServiceRequestDto({
    required super.id,
    required super.name,
    required super.unifiedRequestId,
    required super.category,
    required super.status,
    required super.createdAt,
    required super.updatedAt,
    super.description,
    super.rejectionReason,
    super.images,
  });

  factory ServiceRequestDto.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(MediaRefDto.fromJson)
        .toList();
    return ServiceRequestDto(
      id: json['id'] as String,
      name: json['name'] as String,
      unifiedRequestId: json['unifiedRequestId'] as String,
      category: CategoryRefDto.fromJson(
        json['category'] as Map<String, dynamic>,
      ),
      status: ServiceRequestStatus.fromApi(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      description: json['description'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      images: images,
    );
  }

  @override
  ServiceRequestEntity toEntity() => ServiceRequestEntity(
    id: id,
    name: name,
    unifiedRequestId: unifiedRequestId,
    category: CategoryRefEntity(
      id: category.id,
      name: category.name,
      description: category.description,
    ),
    status: status,
    createdAt: createdAt,
    updatedAt: updatedAt,
    description: description,
    rejectionReason: rejectionReason,
    images: images.map((m) => MediaRefEntity(id: m.id, url: m.url)).toList(),
  );
}
