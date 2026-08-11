import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/widgets/service_actions_bottom_sheet.dart';

/// Per-service detail screen — Figma `4715:26284` (active) / `5119:42089`
/// (paused).
///
/// Receives the already-loaded [ServiceRecordEntity] via the route `extra`
/// (the dashboard list already holds the full record — no extra
/// `GET /services/{id}` round trip needed). Per-service request/revenue/
/// completion-rate metrics are not shown with real numbers: the real
/// `GET /services/analytics` endpoint always reports `dataAvailable: false`
/// today (see `ServiceMetricsSection`), so this screen renders the same
/// "not available yet" placeholder rather than fabricating figures.
class ServiceDetailsPage extends StatefulWidget {
  const ServiceDetailsPage({required this.service, super.key});

  final ServiceRecordEntity service;

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  late ServiceRecordEntity _service;

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
                    if (!_service.isActive) ...[
                      SizedBox(height: AppSpacing.lg),
                      AppAlert(
                        type: AppAlertType.warning,
                        message: 'services.details.paused_banner'.tr(),
                      ),
                    ],
                    SizedBox(height: AppSpacing.lg),
                    const _MetricsUnavailableCard(),
                    SizedBox(height: AppSpacing.lg),
                    _InfoSection(service: _service),
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

  final ServiceRecordEntity service;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Row(
      children: [
        Expanded(
          child: Text(
            service.name,
            style: typography
                .bold(typography.title2)
                .copyWith(
                  color: colors.textPrimary,
                ),
          ),
        ),
        SizedBox(width: AppSpacing.sm),
        AppStatusBadge(
          label: service.isActive
              ? 'services.status_active'.tr()
              : 'services.status_inactive'.tr(),
          type: service.isActive
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

/// Same "analytics coming soon" placeholder as the dashboard's
/// `ServiceMetricsSection` — no per-service `GET /services/analytics` data
/// exists yet (`dataAvailable` is always `false`).
class _MetricsUnavailableCard extends StatelessWidget {
  const _MetricsUnavailableCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

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
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.service});

  final ServiceRecordEntity service;

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
            value: service.name,
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
          if (service.media.isNotEmpty) ...[
            _InfoDivider(),
            Text(
              'services.details.images'.tr(),
              style: context.appTypography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            SizedBox(
              height: responsiveDimension(72),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: service.media.length,
                separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
                itemBuilder: (context, index) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimension.radiusSm),
                  child: Image.network(
                    service.media[index].url,
                    width: responsiveDimension(72),
                    height: responsiveDimension(72),
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ],
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
