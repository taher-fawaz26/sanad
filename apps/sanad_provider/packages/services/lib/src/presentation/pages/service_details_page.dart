import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_overview_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/domain/usecases/get_provider_service_overview_usecase.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/widgets/manage_service_images_section.dart';
import 'package:services/src/presentation/widgets/service_actions_bottom_sheet.dart';
import 'package:shared_ui/shared_ui.dart';

/// Per-service detail screen — Figma `4715:26284` (active) / `5119:42089`
/// (paused).
///
/// Receives the already-loaded [ProviderServiceEntity] via the route
/// `extra` (`GET /provider-services`'s row already carries everything this
/// screen needs). Per-service metrics are wired separately via
/// `GET /provider-services/overview/:id`, gated on `dataAvailable` — see
/// `ServiceMetricsSection`.
class ServiceDetailsPage extends StatefulWidget {
  const ServiceDetailsPage({required this.service, super.key});

  final ProviderServiceEntity service;

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  late ProviderServiceEntity _service;

  @override
  void initState() {
    super.initState();
    _service = widget.service;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ServiceActionBloc, ServiceActionState>(
      listener: _handleActionState,
      child: Scaffold(
        backgroundColor: colors.background,
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
                trailing: AppNotificationIcon(hasUnread: true, onTap: () {}),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  children: [
                    _Header(service: _service, onMoreTap: _onMoreTap),
                    if (_service.status != ProviderServiceStatus.active) ...[
                      SizedBox(height: AppSpacing.lg),
                      AppAlert(
                        type: AppAlertType.warning,
                        message: 'services.details.paused_banner'.tr(),
                      ),
                    ],
                    SizedBox(height: AppSpacing.lg),
                    _ServiceOverviewCard(serviceId: _service.id),
                    SizedBox(height: AppSpacing.lg),
                    _InfoSection(
                      service: _service,
                      onServiceUpdated: (updated) =>
                          setState(() => _service = updated),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onMoreTap() {
    showServiceActionsBottomSheet(context: context, service: _service);
  }

  void _handleActionState(BuildContext context, ServiceActionState state) {
    if (state.status != RequestStatus.success) return;
    if (state.updatedService != null &&
        state.updatedService!.id == _service.id) {
      setState(() => _service = state.updatedService!);
    }
    if (state.deletedServiceId == _service.id) {
      if (context.canPop()) context.pop();
    }
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.service, required this.onMoreTap});

  final ProviderServiceEntity service;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final isActive = service.status == ProviderServiceStatus.active;

    return Row(
      children: [
        Expanded(
          child: Text(
            service.serviceName,
            style: typography
                .bold(typography.title2)
                .copyWith(
                  color: colors.textPrimary,
                ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        AppStatusBadge(
          label: isActive
              ? 'services.status_active'.tr()
              : 'services.status_inactive'.tr(),
          type: isActive
              ? AppStatusBadgeType.success
              : AppStatusBadgeType.warning,
        ),
        SizedBox(width: AppSpacing.sm),
        InkWell(
          onTap: onMoreTap,
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: Icon(Icons.more_vert, color: colors.textPrimary),
          ),
        ),
      ],
    );
  }
}

/// Live per-service overview — `GET /provider-services/overview/:id`,
/// gated on `dataAvailable` (currently always `false` server-side, so this
/// renders the same "coming soon" placeholder as the dashboard's
/// `ServiceMetricsSection` until the backend has real data).
class _ServiceOverviewCard extends StatefulWidget {
  const _ServiceOverviewCard({required this.serviceId});

  final String serviceId;

  @override
  State<_ServiceOverviewCard> createState() => _ServiceOverviewCardState();
}

class _ServiceOverviewCardState extends State<_ServiceOverviewCard> {
  ProviderServiceOverviewEntity? _overview;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await sl<GetProviderServiceOverviewUseCase>()(
      widget.serviceId,
    ).run();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _overview = result.fold((_) => null, (overview) => overview);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const ShimmerListSkeleton();

    final colors = context.appColors;
    final typography = context.appTypography;
    final overview = _overview;

    if (overview == null || !overview.dataAvailable) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          border: Border.all(color: colors.palettes.sky.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'services.metrics_unavailable_title'.tr(),
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              'services.metrics_unavailable_description'.tr(),
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: _OverviewStat(
              label: 'services.metric_orders'.tr(),
              value: overview.totalRequests.toString(),
            ),
          ),
          Expanded(
            child: _OverviewStat(
              label: 'services.metric_completion_rate'.tr(),
              value: '${overview.completionRate}%',
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography.smallNormal.copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: typography
              .medium(typography.title3)
              .copyWith(color: colors.textPrimary, letterSpacing: -0.48),
        ),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.service, required this.onServiceUpdated});

  final ProviderServiceEntity service;
  final ValueChanged<ProviderServiceEntity> onServiceUpdated;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            label: 'services.details.service_name'.tr(),
            value: service.serviceName,
          ),
          _InfoDivider(),
          _InfoRow(
            label: 'services.details.category'.tr(),
            value: service.category.name,
          ),
          if (service.description != null &&
              service.description!.isNotEmpty) ...[
            _InfoDivider(),
            _InfoRow(
              label: 'services.details.description'.tr(),
              value: service.description!,
            ),
          ],
          _InfoDivider(),
          ManageServiceImagesSection(
            service: service,
            onServiceUpdated: onServiceUpdated,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: typography.smallNormal.copyWith(color: colors.textSecondary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: typography
                .semiBold(typography.regularNormal)
                .copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: context.appColors.palettes.sky.shade200,
    );
  }
}
