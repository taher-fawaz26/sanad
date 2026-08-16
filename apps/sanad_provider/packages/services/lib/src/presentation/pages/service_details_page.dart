import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:services/src/domain/entities/category_ref_entity.dart';
import 'package:services/src/domain/entities/provider_service_entity.dart';
import 'package:services/src/domain/entities/provider_service_status.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_details/service_details_bloc.dart';
import 'package:services/src/presentation/widgets/service_actions_bottom_sheet.dart';
import 'package:services/src/presentation/widgets/service_images_preview.dart';
import 'package:shared_ui/shared_ui.dart';

/// Per-service detail screen — Figma `4715:26284` (active) / `5119:42089`
/// (paused).
///
/// Renders [ServiceDetailsBloc] state — the bloc fetches the full,
/// up-to-date service via `GET /provider-services/:id` rather than trusting
/// the row `extra` from the services list (the list endpoint's rows carry
/// only a subset of what this screen needs, e.g. only `primaryImage`, not
/// the full `images` array, and no `requests`/`revenue`), and folds in
/// updates from [ServiceActionBloc] (status toggle / delete) so this page
/// stays purely presentational.
class ServiceDetailsPage extends StatelessWidget {
  const ServiceDetailsPage({super.key});

  /// Realistic mock used only to skeletonize the real layout via
  /// [AppSkeletonizer] — no bespoke skeleton widget.
  static final _skeletonService = ProviderServiceEntity(
    id: 'skeleton',
    serviceId: 'skeleton',
    serviceName: BoneMock.words(3),
    category: CategoryRefEntity(
      id: 'skeleton',
      name: BoneMock.name,
      description: null,
    ),
    description: BoneMock.words(8),
    status: ProviderServiceStatus.active,
    images: const [],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

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
                trailingAction: AppNavBarTrailingAction.icon,
                trailing: AppNotificationIcon(hasUnread: true, onTap: () {}),
              ),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return BlocBuilder<ServiceDetailsBloc, ServiceDetailsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return AppSkeletonizer(
            enabled: true,
            child: _buildContent(context, _skeletonService),
          );
        }

        final service = state.service;
        if (service == null) {
          final display = failureErrorDisplay(state.failure);
          return Center(
            child: AppErrorState(
              style: display.isConnectivity
                  ? AppErrorStateStyle.network
                  : AppErrorStateStyle.generic,
              title: display.title,
              description: display.description,
              retryLabel: failureRetryLabel(),
              onRetry: display.isRetryable
                  ? () => _fetch(context)
                  : null,
            ),
          );
        }

        return _buildContent(context, service);
      },
    );
  }

  Widget _buildContent(BuildContext context, ProviderServiceEntity service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _Header(
            service: service,
            onMoreTap: () => _onMoreTap(context, service),
          ),
        ),
        if (service.status != ProviderServiceStatus.active)
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.lg,
              AppSpacing.xl,
              0,
            ),
            child: AppAlert(
              type: AppAlertType.warning,
              message: 'services.details.paused_banner'.tr(),
            ),
          ),
        Expanded(
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.md,
            ),
            children: [
              _ServiceMetricsCard(service: service),
              SizedBox(height: AppSpacing.md),
              _InfoSection(service: service),
            ],
          ),
        ),
      ],
    );
  }

  void _fetch(BuildContext context) {
    final serviceId = context.read<ServiceDetailsBloc>().state.serviceId;
    if (serviceId != null) {
      context.read<ServiceDetailsBloc>().add(
        ServiceDetailsFetchRequested(serviceId),
      );
    }
  }

  void _onMoreTap(BuildContext context, ProviderServiceEntity service) {
    showServiceActionsBottomSheet(context: context, service: service);
  }

  void _handleActionState(BuildContext context, ServiceActionState state) {
    if (state.status != RequestStatus.success) return;
    final current = context.read<ServiceDetailsBloc>().state.service;
    if (current == null) return;

    if (state.updatedService != null &&
        state.updatedService!.id == current.id) {
      context.read<ServiceDetailsBloc>().add(
        ServiceDetailsExternallyUpdated(state.updatedService!),
      );
    }
    if (state.deletedServiceId == current.id) {
      if (context.canPop()) context.pop();
    }
  }
}

/// Figma `5261:44570` — service name, status pill, and more-options button.
class _Header extends StatelessWidget {
  const _Header({required this.service, required this.onMoreTap});

  final ProviderServiceEntity service;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isActive = service.status == ProviderServiceStatus.active;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsiveSpacing(14)),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    service.serviceName,
                    style: typography
                        .semiBold(typography.title3)
                        .copyWith(
                          color: OverlayTokens.ink900,
                          height: 1.50,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(width: AppSpacing.md),
                AppStatusBadge(
                  label: isActive
                      ? 'services.status_active'.tr()
                      : 'services.status_inactive'.tr(),
                  type: isActive
                      ? AppStatusBadgeType.success
                      : AppStatusBadgeType.warning,
                  outlined: true,
                ),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Material(
            color: colors.surface,
            borderRadius: BorderRadius.circular(responsiveDimension(9)),
            child: InkWell(
              onTap: onMoreTap,
              borderRadius: BorderRadius.circular(responsiveDimension(9)),
              child: SizedBox(
                width: responsiveDimension(34),
                height: responsiveDimension(34),
                child: Icon(
                  Icons.more_vert,
                  size: responsiveDimension(20),
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Requests + revenue, straight from the by-id detail response — the fleet
/// "overview" endpoint is not used here (it never had per-service numbers;
/// `requests`/`revenue` live directly on `GET /provider-services/:id`).
class _ServiceMetricsCard extends StatelessWidget {
  const _ServiceMetricsCard({required this.service});

  final ProviderServiceEntity service;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'services.card_requests'.tr(),
            value: NumberFormat('#,###').format(service.requests),
          ),
        ),
        SizedBox(width: responsiveSpacing(14)),
        Expanded(
          child: _MetricTile(
            label: 'services.card_revenue'.tr(),
            value: NumberFormat('#,###').format(service.revenue),
            valueTrailing: Image.asset(
              AppImages.dirham,
              package: AppAssets.package,
              width: responsiveDimension(18),
              height: responsiveDimension(16),
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}

/// A single bordered KPI card — Figma `5643:27527`/`5643:27541`.
class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
    this.valueTrailing,
  });

  final String label;
  final String value;
  final Widget? valueTrailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final valueTextStyle = typography
        .medium(typography.regularNormal)
        .copyWith(
          fontSize: 20.rfs,
          color: colors.textPrimary,
          letterSpacing: -0.4,
        );

    final valueWidget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: valueTextStyle,
          ),
        ),
        if (valueTrailing != null) ...[
          SizedBox(width: AppSpacing.xs),
          valueTrailing!,
        ],
      ],
    );

    final labelStyle = typography
        .medium(typography.smallNormal)
        .copyWith(color: colors.palettes.sky.shade700);

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: labelStyle,
        ),
        SizedBox(height: responsiveSpacing(6)),
        valueWidget,
      ],
    );

    return Container(
      width: double.infinity,
      constraints: BoxConstraints(minHeight: responsiveDimension(80)),
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xxl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: content,
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.service});

  final ProviderServiceEntity service;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final hasDescription =
        service.description != null && service.description!.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.xl),
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
          SizedBox(height: AppSpacing.xl),
          const _InfoDivider(),
          SizedBox(height: AppSpacing.xl),
          _InfoRow(
            label: 'services.details.category'.tr(),
            value: service.category.name,
          ),
          if (hasDescription) ...[
            SizedBox(height: AppSpacing.xl),
            const _InfoDivider(),
            SizedBox(height: AppSpacing.xl),
            _InfoDescriptionRow(
              label: 'services.details.description'.tr(),
              value: service.description!,
            ),
          ],
          SizedBox(height: AppSpacing.xl),
          const _InfoDivider(),
          SizedBox(height: AppSpacing.xl),
          ServiceImagesPreview(images: service.images),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: typography
              .medium(typography.smallNormal)
              .copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: typography
              .semiBold(typography.regularNormal)
              .copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _InfoDescriptionRow extends StatelessWidget {
  const _InfoDescriptionRow({required this.label, required this.value});

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
          style: typography
              .medium(typography.smallNormal)
              .copyWith(color: colors.textSecondary),
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: typography.regularNormal.copyWith(
            fontSize: 15.rfs,
            height: 22 / 15,
            color: colors.palettes.dark.shade700,
          ),
        ),
      ],
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
