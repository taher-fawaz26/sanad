import 'package:equatable/equatable.dart';

/// `OverallMetricsDto`.
class OverallMetricsEntity extends Equatable {
  const OverallMetricsEntity({
    required this.totalRequests,
    required this.totalRevenue,
  });

  const OverallMetricsEntity.zero() : totalRequests = 0, totalRevenue = 0;

  final num totalRequests;
  final num totalRevenue;

  @override
  List<Object?> get props => [totalRequests, totalRevenue];
}

/// `CompletionMetricsDto`.
class CompletionMetricsEntity extends Equatable {
  const CompletionMetricsEntity({
    required this.completedCount,
    required this.cancelledCount,
    required this.completionRate,
  });

  const CompletionMetricsEntity.zero()
    : completedCount = 0,
      cancelledCount = 0,
      completionRate = 0;

  final num completedCount;
  final num cancelledCount;
  final num completionRate;

  @override
  List<Object?> get props => [completedCount, cancelledCount, completionRate];
}

/// `ServiceMetricsDto` — per-service row.
class ServiceMetricsEntity extends Equatable {
  const ServiceMetricsEntity({
    required this.serviceId,
    required this.name,
    required this.requestCount,
    required this.revenue,
  });

  final String serviceId;
  final String name;
  final num requestCount;
  final num revenue;

  @override
  List<Object?> get props => [serviceId, name, requestCount, revenue];
}

/// `ServiceAnalyticsResponseDto`.
///
/// Per the live API description, `dataAvailable` is currently always
/// `false` because the booking entity does not exist yet — every metric
/// below is a placeholder zero in that case. Callers MUST gate on
/// [dataAvailable] and show a "not available yet" state rather than
/// rendering the zeros as real numbers.
class ServiceAnalyticsEntity extends Equatable {
  const ServiceAnalyticsEntity({
    required this.dataAvailable,
    required this.overall,
    required this.completion,
    required this.perService,
  });

  final bool dataAvailable;
  final OverallMetricsEntity overall;
  final CompletionMetricsEntity completion;
  final List<ServiceMetricsEntity> perService;

  @override
  List<Object?> get props => [dataAvailable, overall, completion, perService];
}
