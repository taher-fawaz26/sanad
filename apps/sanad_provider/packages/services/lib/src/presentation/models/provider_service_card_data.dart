import 'package:easy_localization/easy_localization.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';

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

  /// Builds card data from the real `ProviderServiceDto`-backed entity
  /// (`GET /provider-services`).
  ///
  /// [requestsCount]/[revenueLabel] are static "0" placeholders — the new
  /// contract has no price/revenue field anywhere and no per-card request
  /// count on this endpoint (only a fleet-wide overview, currently always
  /// `dataAvailable: false`). Shown as `0` per product decision until the
  /// backend exposes real per-service numbers here.
  factory ProviderServiceCardData.fromEntity(ProviderServiceEntity service) =>
      ProviderServiceCardData(
        id: service.id,
        name: service.serviceName,
        category: service.category.name,
        description: service.description ?? '',
        statusLabel: service.status == ProviderServiceStatus.active
            ? 'services.status_active'.tr()
            : 'services.status_inactive'.tr(),
        isActive: service.status == ProviderServiceStatus.active,
        requestsCount: '0',
        revenueLabel: '0 ${'services.currency_aed'.tr()}',
        coverImageUrl: service.primaryImage?.url,
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
