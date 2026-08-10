import 'package:core/core.dart';
import 'package:services/src/domain/entities/service_request_category_summary_entity.dart';

class ServiceRequestCategorySummaryDto
    extends ServiceRequestCategorySummaryEntity
    implements EntityConverter<ServiceRequestCategorySummaryEntity> {
  const ServiceRequestCategorySummaryDto({
    required super.id,
    required super.name,
    required super.slug,
  });

  factory ServiceRequestCategorySummaryDto.fromJson(
    Map<String, dynamic> json,
  ) => ServiceRequestCategorySummaryDto(
    id: json['id'] as String,
    name: json['name'] as String,
    slug: json['slug'] as String,
  );

  @override
  ServiceRequestCategorySummaryEntity toEntity() =>
      ServiceRequestCategorySummaryEntity(id: id, name: name, slug: slug);
}
