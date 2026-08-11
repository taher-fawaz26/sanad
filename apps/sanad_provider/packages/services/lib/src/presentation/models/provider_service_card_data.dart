import 'package:easy_localization/easy_localization.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';

/// UI model for a provider service card on the services dashboard.
class ProviderServiceCardData {
  const ProviderServiceCardData({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.statusLabel,
    required this.isActive,
    required this.requestsCount,
    required this.revenueLabel,
    this.coverImageUrl,
    this.showMoreAction = true,
  });

  /// Builds card data from the real `ServiceResponseDto`-backed entity.
  ///
  /// [perServiceMetrics] is the matching `ServiceMetricsDto` row from
  /// `GET /services/analytics`'s `perService` list, matched by
  /// `service.id`. Shown as-is (including `0`) once the analytics call
  /// resolves — unlike the dashboard's aggregate `ServiceMetricsSection`,
  /// per-card stats are not gated on `dataAvailable` (product decision:
  /// `perService` rows are real per-service data from the same response,
  /// just mostly zero until bookings exist). Falls back to a "—"
  /// placeholder only while analytics hasn't loaded yet / no matching row
  /// exists for this service.
  factory ProviderServiceCardData.fromEntity(
    ServiceRecordEntity service, {
    ServiceMetricsEntity? perServiceMetrics,
  }) => ProviderServiceCardData(
    id: service.id,
    name: service.name,
    category: service.category.name,
    description: service.description ?? '',
    statusLabel: service.isActive
        ? 'services.status_active'.tr()
        : 'services.status_inactive'.tr(),
    isActive: service.isActive,
    requestsCount: perServiceMetrics?.requestCount.toString() ?? '—',
    revenueLabel: perServiceMetrics == null
        ? '—'
        : '${perServiceMetrics.revenue} ${'services.currency_aed'.tr()}',
    coverImageUrl: service.media.isEmpty ? null : service.media.first.url,
  );

  final String id;
  final String name;
  final String category;
  final String description;
  final String statusLabel;
  final bool isActive;
  final String requestsCount;
  final String revenueLabel;
  final String? coverImageUrl;
  final bool showMoreAction;
}
