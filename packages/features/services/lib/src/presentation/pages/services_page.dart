import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/presentation/models/provider_service_card_data.dart';
import 'package:services/src/presentation/widgets/service_metrics_section.dart';
import 'package:services/src/presentation/widgets/service_provider_card.dart';
import 'package:services/src/presentation/widgets/services_empty_state.dart';
import 'package:services/src/presentation/widgets/services_filter_bar.dart';
import 'package:services/src/routes/service_routes.dart';

/// Provider services screen — Figma `4715:25922` (dashboard) and
/// `4715:23588` (empty state).
///
/// UI-only for now: seeded with demo cards so the dashboard layout can be
/// reviewed. Pass [services] as an empty list to preview the empty state.
class ProviderServicesPage extends StatefulWidget {
  /// Creates the provider services dashboard / empty-state screen.
  const ProviderServicesPage({
    super.key,
    this.services,
  });

  /// When null, demo cards matching the Figma dashboard are shown.
  final List<ProviderServiceCardData>? services;

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final services = widget.services ?? _demoServices();
    final isMyServices = _selectedTab == 0;
    final showEmpty = isMyServices && services.isEmpty;

    return Scaffold(
      backgroundColor: showEmpty ? colors.surface : colors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: 'services.title'.tr(),
              showBackButton: true,
              onLeadingTap: () {
                if (context.canPop()) context.pop();
              },
              trailing: AppNotificationIcon(
                hasUnread: true,
                onTap: () {},
              ),
            ),
            if (showEmpty) ...[
              AppLargeNavBar(title: 'services.title'.tr()),
              Expanded(
                child: ServicesEmptyState(onAddService: _onAddService),
              ),
            ] else ...[
              _DashboardHeader(onAddService: _onAddService),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: AppSegmentedControl(
                  segments: [
                    'services.tab_my_services'.tr(),
                    'services.tab_service_request'.tr(),
                  ],
                  selectedIndex: _selectedTab,
                  onChanged: (index) => setState(() => _selectedTab = index),
                ),
              ),
              Expanded(
                child: isMyServices
                    ? _MyServicesContent(
                        services: services,
                        onAddService: _onAddService,
                      )
                    : const ServiceRequestsEmptyState(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _onAddService() {
    context.push(ServiceRoutes.add);
  }

  static List<ProviderServiceCardData> _demoServices() {
    return [
      ProviderServiceCardData(
        id: '1',
        name: 'AC Repair',
        category: 'Home Maintenance',
        description:
            'Inspection, maintenance, and repair services for residential '
            'air-conditioning systems.',
        statusLabel: 'services.status_active'.tr(),
        requestsCount: '128',
        revenueLabel: '24,680 ${'services.currency_aed'.tr()}',
        coverAssetPath: AppImages.serviceCoverAc,
        showMoreAction: false,
      ),
      ProviderServiceCardData(
        id: '2',
        name: 'Plumbing',
        category: 'Home Services',
        description:
            'Installation, maintenance, and emergency repair services for '
            'residential water pipes, fixtures, and drainage systems.',
        statusLabel: 'services.status_active'.tr(),
        requestsCount: '95',
        revenueLabel: '18,350 ${'services.currency_aed'.tr()}',
        coverAssetPath: AppImages.serviceCoverPlumbing,
      ),
      ProviderServiceCardData(
        id: '3',
        name: 'Electrical',
        category: 'Home Services',
        description:
            'Comprehensive electrical wiring and installation services for '
            'residential properties, including circuit upgrades and safety '
            'inspections.',
        statusLabel: 'services.status_active'.tr(),
        requestsCount: '72',
        revenueLabel: '15,200 ${'services.currency_aed'.tr()}',
        coverAssetPath: AppImages.serviceCoverElectrical,
      ),
    ];
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.onAddService});

  final VoidCallback onAddService;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'services.dashboard'.tr(),
              style: typography.title3.copyWith(color: colors.textPrimary),
            ),
          ),
          AppButton(
            label: 'services.add_new_service'.tr(),
            onPressed: onAddService,
            type: AppButtonType.outline,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }
}

class _MyServicesContent extends StatelessWidget {
  const _MyServicesContent({
    required this.services,
    required this.onAddService,
  });

  final List<ProviderServiceCardData> services;
  final VoidCallback onAddService;

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return ServicesEmptyState(onAddService: onAddService);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      children: [
        const ServiceMetricsSection(),
        SizedBox(height: AppSpacing.lg),
        const ServicesFilterBar(),
        SizedBox(height: AppSpacing.xl),
        ...services.map(
          (service) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.xl),
            child: ServiceProviderCard(
              data: service,
              onMoreTap: () {},
            ),
          ),
        ),
      ],
    );
  }
}
