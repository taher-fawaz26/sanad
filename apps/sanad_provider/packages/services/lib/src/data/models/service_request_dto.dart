import 'package:core/core.dart';
import 'package:services/src/data/models/service_media_dto.dart';
import 'package:services/src/data/models/service_request_category_summary_dto.dart';
import 'package:services/src/domain/entities/service_media_entity.dart';
import 'package:services/src/domain/entities/service_request_category_summary_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';

class ServiceRequestDto extends ServiceRequestEntity
    implements EntityConverter<ServiceRequestEntity> {
  const ServiceRequestDto({
    required super.id,
    required super.requestedServiceName,
    required super.requestedCategoryName,
    required super.description,
    required super.status,
    required super.rejectionReason,
    required super.reviewedAt,
    required super.providerId,
    required super.resultingCategory,
    required super.media,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ServiceRequestDto.fromJson(Map<String, dynamic> json) {
    final resultingCategoryJson =
        json['resultingCategory'] as Map<String, dynamic>?;
    final media = (json['media'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(ServiceMediaDto.fromJson)
        .toList();
    final reviewedAt = json['reviewedAt'] as String?;
    return ServiceRequestDto(
      id: json['id'] as String,
      requestedServiceName: json['requestedServiceName'] as String?,
      requestedCategoryName: json['requestedCategoryName'] as String?,
      description: json['description'] as String,
      status: ServiceRequestStatus.fromApi(json['status'] as String),
      rejectionReason: json['rejectionReason'] as String?,
      reviewedAt: reviewedAt == null ? null : DateTime.parse(reviewedAt),
      providerId: json['providerId'] as String,
      resultingCategory: resultingCategoryJson == null
          ? null
          : ServiceRequestCategorySummaryDto.fromJson(resultingCategoryJson),
      media: media,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  @override
  ServiceRequestEntity toEntity() => ServiceRequestEntity(
    id: id,
    requestedServiceName: requestedServiceName,
    requestedCategoryName: requestedCategoryName,
    description: description,
    status: status,
    rejectionReason: rejectionReason,
    reviewedAt: reviewedAt,
    providerId: providerId,
    resultingCategory: resultingCategory == null
        ? null
        : ServiceRequestCategorySummaryEntity(
            id: resultingCategory!.id,
            name: resultingCategory!.name,
            slug: resultingCategory!.slug,
          ),
    media: media
        .map((m) => ServiceMediaEntity(id: m.id, url: m.url, type: m.type))
        .toList(),
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}
