import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:services/src/domain/entities/service_analytics_entity.dart';
import 'package:services/src/domain/entities/service_record_entity.dart';
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';
import 'package:services/src/presentation/models/provider_service_card_data.dart';
import 'package:services/src/presentation/widgets/service_actions_bottom_sheet.dart';
import 'package:services/src/presentation/widgets/service_metrics_section.dart';
import 'package:services/src/presentation/widgets/service_provider_card.dart';
import 'package:services/src/presentation/widgets/service_request_list_item.dart';
import 'package:services/src/presentation/widgets/services_empty_state.dart';
import 'package:services/src/presentation/widgets/services_filter_bar.dart';
import 'package:services/src/routes/service_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Provider services screen — Figma `4715:25922` (dashboard) and
/// `4715:23588` (empty state).
///
/// Real backend integration: services list (`GET /services`), analytics
/// (`GET /services/analytics`), and the provider's own service requests
/// (`GET /service-requests/mine`). Expects `ServicesListBloc`,
/// `ServiceActionBloc`, `ServiceAnalyticsBloc`, and `ServiceRequestsListBloc`
/// above it in the tree (wired by `ServicesModule`).
class ProviderServicesPage extends StatefulWidget {
  /// Creates the provider services dashboard / empty-state screen.
  ///
  /// [initialTab] lets the Request-Submitted success popover land directly
  /// on the Service Requests tab (`1`) via `context.go(ServiceRoutes.list,
  /// extra: 1)`; defaults to My Services (`0`).
  const ProviderServicesPage({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  late int _selectedTab = widget.initialTab;

  @override
  void initState() {
    super.initState();
    context.read<ServicesListBloc>().add(const ServicesListFetchEvent());
    context.read<ServiceAnalyticsBloc>().add(
      const ServiceAnalyticsFetchEvent(),
    );
    context.read<ServiceRequestsListBloc>().add(
      const ServiceRequestsListFetchEvent(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ServiceActionBloc, ServiceActionState>(
      listener: _handleActionState,
      child: BlocBuilder<ServicesListBloc, ServicesListState>(
        builder: (context, listState) {
          final isMyServices = _selectedTab == 0;
          final showEmpty =
              isMyServices &&
              listState.status == RequestStatus.success &&
              listState.services.isEmpty;

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
                        onChanged: (index) =>
                            setState(() => _selectedTab = index),
                      ),
                    ),
                    Expanded(
                      child: isMyServices
                          ? _MyServicesContent(
                              state: listState,
                              onAddService: _onAddService,
                            )
                          : const _ServiceRequestsContent(),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _onAddService() {
    context.push(ServiceRoutes.add).then((_) {
      if (!mounted) return;
      context.read<ServicesListBloc>().add(const ServicesListRefreshEvent());
    });
  }

  void _handleActionState(BuildContext context, ServiceActionState state) {
    if (state.status == RequestStatus.success) {
      if (state.updatedService != null) {
        context.read<ServicesListBloc>().add(
          ServiceReplacedInListEvent(state.updatedService!),
        );
      }
      if (state.deletedServiceId != null) {
        context.read<ServicesListBloc>().add(
          ServiceRemovedFromListEvent(state.deletedServiceId!),
        );
      }
      return;
    }
    if (state.status == RequestStatus.failure && state.failure != null) {
      final display = failureErrorDisplay(state.failure);
      showAppSnackbar(
        context: context,
        title: display.title,
        caption: display.description,
        color: AppSnackbarColor.error,
        layout: AppSnackbarLayout.fullWidth,
      );
    }
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

/// Matches a service's real per-service row from `GET /services/analytics`'s
/// `perService` list — shown regardless of `dataAvailable` (see
/// `ProviderServiceCardData.fromEntity`).
ServiceMetricsEntity? _metricsFor(
  ServiceAnalyticsState state,
  String serviceId,
) {
  final perService = state.analytics?.perService;
  if (perService == null) return null;
  for (final metrics in perService) {
    if (metrics.serviceId == serviceId) return metrics;
  }
  return null;
}

class _MyServicesContent extends StatefulWidget {
  const _MyServicesContent({required this.state, required this.onAddService});

  final ServicesListState state;
  final VoidCallback onAddService;

  @override
  State<_MyServicesContent> createState() => _MyServicesContentState();
}

class _MyServicesContentState extends State<_MyServicesContent> {
  late final _searchController = TextEditingController(
    text: widget.state.searchQuery,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceTap(BuildContext context, ServiceRecordEntity service) {
    context.push(ServiceRoutes.detailsFor(service.id), extra: service).then((
      _,
    ) {
      if (!context.mounted) return;
      context.read<ServicesListBloc>().add(const ServicesListRefreshEvent());
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final onAddService = widget.onAddService;

    if (state.isLoading && state.services.isEmpty) {
      return const ShimmerListSkeleton();
    }

    if (state.hasError && state.services.isEmpty) {
      return AppFillRemainingScrollable(
        child: _ServicesErrorState(
          failure: state.failure,
          onRetry: () => context.read<ServicesListBloc>().add(
            const ServicesListFetchEvent(),
          ),
        ),
      );
    }

    if (state.services.isEmpty) {
      return ServicesEmptyState(onAddService: onAddService);
    }

    return AppRefreshIndicator(
      onRefresh: () async => context.read<ServicesListBloc>().add(
        const ServicesListRefreshEvent(),
      ),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.pixels >=
                  notification.metrics.maxScrollExtent - 200 &&
              state.hasMore &&
              !state.loadingMore) {
            context.read<ServicesListBloc>().add(
              const ServicesListLoadMoreEvent(),
            );
          }
          return false;
        },
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.md,
            AppSpacing.xl,
            AppSpacing.xl,
          ),
          children: [
            const ServiceMetricsSection(),
            SizedBox(height: AppSpacing.lg),
            ServicesFilterBar(
              searchController: _searchController,
              onSearchChanged: (query) => context.read<ServicesListBloc>().add(
                ServicesListSearchChangedEvent(query),
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            ...state.services.map(
              (service) => Padding(
                key: ValueKey(service.id),
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: ServiceProviderCard(
                  data: ProviderServiceCardData.fromEntity(
                    service,
                    perServiceMetrics: context
                        .select<ServiceAnalyticsBloc, ServiceMetricsEntity?>(
                          (bloc) => _metricsFor(bloc.state, service.id),
                        ),
                  ),
                  onTap: () => _onServiceTap(context, service),
                  onMoreTap: () => showServiceActionsBottomSheet(
                    context: context,
                    service: service,
                  ),
                ),
              ),
            ),
            if (state.loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: AppLoadingIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}

class _ServicesErrorState extends StatelessWidget {
  const _ServicesErrorState({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(failure);
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}

/// Client-side status filter for the Service Requests tab — Figma
/// `4749:20243`'s All/Review/Approved/Rejected chips.
///
/// Filters only what `ServiceRequestsListBloc` has already loaded; the
/// backend/bloc have no server-side status-filter or search parameter, so
/// this intentionally does not request additional pages per filter (see
/// audit blockers).
enum _RequestFilter { all, review, approved, rejected }

class _ServiceRequestsContent extends StatefulWidget {
  const _ServiceRequestsContent();

  @override
  State<_ServiceRequestsContent> createState() =>
      _ServiceRequestsContentState();
}

class _ServiceRequestsContentState extends State<_ServiceRequestsContent> {
  final _searchController = TextEditingController();
  _RequestFilter _filter = _RequestFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ServiceRequestEntity> _filtered(List<ServiceRequestEntity> requests) {
    return requests.where((request) {
      final matchesFilter = switch (_filter) {
        _RequestFilter.all => true,
        _RequestFilter.review => request.status == ServiceRequestStatus.pending,
        _RequestFilter.approved =>
          request.status == ServiceRequestStatus.approved,
        _RequestFilter.rejected =>
          request.status == ServiceRequestStatus.rejected,
      };
      if (!matchesFilter) return false;
      if (_query.isEmpty) return true;
      return request.displayName.toLowerCase().contains(_query.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceRequestsListBloc, ServiceRequestsListState>(
      builder: (context, state) {
        if (state.isLoading && state.requests.isEmpty) {
          return const ShimmerListSkeleton();
        }

        if (state.hasError && state.requests.isEmpty) {
          return AppFillRemainingScrollable(
            child: _ServicesErrorState(
              failure: state.failure,
              onRetry: () => context.read<ServiceRequestsListBloc>().add(
                const ServiceRequestsListFetchEvent(),
              ),
            ),
          );
        }

        if (state.requests.isEmpty) {
          return const ServiceRequestsEmptyState();
        }

        final filtered = _filtered(state.requests);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppSearchField(
                    controller: _searchController,
                    variant: AppSearchFieldVariant.bordered,
                    hint: 'services.search_hint'.tr(),
                    showMicIcon: false,
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final option in _RequestFilter.values) ...[
                          AppChip(
                            label: _filterLabel(option),
                            selected: _filter == option,
                            onTap: () => setState(() => _filter = option),
                          ),
                          SizedBox(width: AppSpacing.sm),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? const ServiceRequestsEmptyState()
                  : AppRefreshIndicator(
                      onRefresh: () async =>
                          context.read<ServiceRequestsListBloc>().add(
                            const ServiceRequestsListRefreshEvent(),
                          ),
                      child: NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200 &&
                              state.hasMore &&
                              !state.loadingMore) {
                            context.read<ServiceRequestsListBloc>().add(
                              const ServiceRequestsListLoadMoreEvent(),
                            );
                          }
                          return false;
                        },
                        child: ListView.separated(
                          padding: EdgeInsets.all(AppSpacing.xl),
                          itemCount:
                              filtered.length + (state.loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              SizedBox(height: AppSpacing.md),
                          itemBuilder: (context, index) {
                            if (index >= filtered.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: AppLoadingIndicator()),
                              );
                            }
                            final request = filtered[index];
                            return ServiceRequestListItem(
                              key: ValueKey(request.id),
                              request: request,
                              onTap: () => context.push(
                                ServiceRoutes.requestDetailsFor(request.id),
                                extra: request,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  static String _filterLabel(_RequestFilter filter) => switch (filter) {
    _RequestFilter.all => 'services.requests_filter_all'.tr(),
    _RequestFilter.review => 'services.requests_filter_review'.tr(),
    _RequestFilter.approved => 'services.requests_filter_approved'.tr(),
    _RequestFilter.rejected => 'services.requests_filter_rejected'.tr(),
  };
}
