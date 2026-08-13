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
import 'package:services/src/domain/usecases/get_provider_service_usecase.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/widgets/service_actions_bottom_sheet.dart';
import 'package:services/src/presentation/widgets/service_images_preview.dart';
import 'package:shared_ui/shared_ui.dart';

/// Per-service detail screen — Figma `4715:26284` (active) / `5119:42089`
/// (paused).
///
/// Fetches the full, up-to-date service via `GET /provider-services/:id`
/// (`GetProviderServiceUseCase`) rather than trusting the row `extra` from
/// the services list — the list endpoint's rows carry only a subset of what
/// this screen needs (e.g. only `primaryImage`, not the full `images` array,
/// and no `requests`/`revenue`).
class ServiceDetailsPage extends StatefulWidget {
  const ServiceDetailsPage({required this.serviceId, super.key});

  final String serviceId;

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  ProviderServiceEntity? _service;
  Failure? _loadFailure;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _loadFailure = null;
    });

    final result = await sl<GetProviderServiceUseCase>()(
      widget.serviceId,
    ).run();
    if (!mounted) return;

    result.fold(
      (failure) => setState(() {
        _isLoading = false;
        _loadFailure = failure;
      }),
      (service) => setState(() {
        _isLoading = false;
        _service = service;
      }),
    );
  }

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
    if (_isLoading) {
      return AppSkeletonizer(
        enabled: true,
        child: _buildContent(_skeletonService),
      );
    }

    final service = _service;
    if (service == null) {
      final display = failureErrorDisplay(_loadFailure);
      return Center(
        child: AppErrorState(
          style: display.isConnectivity
              ? AppErrorStateStyle.network
              : AppErrorStateStyle.generic,
          title: display.title,
          description: display.description,
          retryLabel: failureRetryLabel(),
          onRetry: display.isRetryable ? _load : null,
        ),
      );
    }

    return _buildContent(service);
  }

  Widget _buildContent(ProviderServiceEntity service) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: _Header(
            service: service,
            onMoreTap: () => _onMoreTap(service),
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

  void _onMoreTap(ProviderServiceEntity service) {
    showServiceActionsBottomSheet(context: context, service: service);
  }

  void _handleActionState(BuildContext context, ServiceActionState state) {
    if (state.status != RequestStatus.success) return;
    final current = _service;
    if (current == null) return;

    if (state.updatedService != null &&
        state.updatedService!.id == current.id) {
      setState(() => _service = state.updatedService);
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
