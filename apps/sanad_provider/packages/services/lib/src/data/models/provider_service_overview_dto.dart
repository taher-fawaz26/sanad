import 'package:core/core.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';

/// `GET /provider-services/overview[/:id]` — currently always returns
/// `dataAvailable: false` with stubbed zero metrics server-side.
class ProviderServiceOverviewDto extends ProviderServiceOverviewEntity
    implements EntityConverter<ProviderServiceOverviewEntity> {
  const ProviderServiceOverviewDto({
    required super.dataAvailable,
    required super.totalRequests,
    required super.completedCount,
    required super.cancelledCount,
    required super.completionRate,
  });

  factory ProviderServiceOverviewDto.fromJson(Map<String, dynamic> json) =>
      ProviderServiceOverviewDto(
        dataAvailable: json['dataAvailable'] as bool? ?? false,
        totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
        completedCount: (json['completedCount'] as num?)?.toInt() ?? 0,
        cancelledCount: (json['cancelledCount'] as num?)?.toInt() ?? 0,
        completionRate: (json['completionRate'] as num?) ?? 0,
      );

  @override
  ProviderServiceOverviewEntity toEntity() => ProviderServiceOverviewEntity(
    dataAvailable: dataAvailable,
    totalRequests: totalRequests,
    completedCount: completedCount,
    cancelledCount: cancelledCount,
    completionRate: completionRate,
  );
}
