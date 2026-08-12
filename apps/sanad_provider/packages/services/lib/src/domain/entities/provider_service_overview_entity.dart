import 'package:equatable/equatable.dart';

/// `GET /provider-services/overview` (fleet-wide) and
/// `GET /provider-services/overview/:id` (per-service) response.
///
/// The backend currently always returns [dataAvailable] = false with
/// stubbed zero metrics. UI must gate on [dataAvailable] and never present
/// the stub as real analytics — see `services.metrics_unavailable_*`.
class ProviderServiceOverviewEntity extends Equatable {
  const ProviderServiceOverviewEntity({
    required this.dataAvailable,
    required this.totalRequests,
    required this.completedCount,
    required this.cancelledCount,
    required this.completionRate,
  });

  const ProviderServiceOverviewEntity.unavailable()
    : dataAvailable = false,
      totalRequests = 0,
      completedCount = 0,
      cancelledCount = 0,
      completionRate = 0;

  final bool dataAvailable;
  final int totalRequests;
  final int completedCount;
  final int cancelledCount;
  final num completionRate;

  @override
  List<Object?> get props => [
    dataAvailable,
    totalRequests,
    completedCount,
    cancelledCount,
    completionRate,
  ];
}
