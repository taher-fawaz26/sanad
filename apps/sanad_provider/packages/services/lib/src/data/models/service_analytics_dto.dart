import 'package:services/src/domain/entities/service_analytics_entity.dart';

/// Parses `ServiceAnalyticsResponseDto` directly into the domain entity —
/// there is no separate identity to preserve, so no `EntityConverter` split
/// is needed here (unlike the other DTOs in this package).
abstract final class ServiceAnalyticsDto {
  ServiceAnalyticsDto._();

  static ServiceAnalyticsEntity fromJson(Map<String, dynamic> json) {
    final overall = json['overall'] as Map<String, dynamic>;
    final completion = json['completion'] as Map<String, dynamic>;
    final perService = (json['perService'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(
          (m) => ServiceMetricsEntity(
            serviceId: m['serviceId'] as String,
            name: m['name'] as String,
            requestCount: m['requestCount'] as num,
            revenue: m['revenue'] as num,
            completedCount: m['completedCount'] as num,
            cancelledCount: m['cancelledCount'] as num,
            completionRate: m['completionRate'] as num,
          ),
        )
        .toList();

    return ServiceAnalyticsEntity(
      dataAvailable: json['dataAvailable'] as bool,
      overall: OverallMetricsEntity(
        totalRequests: overall['totalRequests'] as num,
        totalRevenue: overall['totalRevenue'] as num,
      ),
      completion: CompletionMetricsEntity(
        completedCount: completion['completedCount'] as num,
        cancelledCount: completion['cancelledCount'] as num,
        completionRate: completion['completionRate'] as num,
      ),
      perService: perService,
    );
  }
}
