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
import 'package:services/src/domain/entities/service_request_entity.dart';
import 'package:services/src/domain/entities/service_request_status.dart';
import 'package:services/src/presentation/bloc/service_action/service_action_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:services/src/presentation/bloc/service_requests_list/service_requests_list_bloc.dart';
import 'package:services/src/presentation/bloc/services_list/services_list_bloc.dart';
import 'package:services/src/presentation/widgets/service_list_item.dart';
import 'package:services/src/presentation/widgets/service_metrics_section.dart';
import 'package:services/src/presentation/widgets/service_request_list_item.dart';
import 'package:services/src/presentation/widgets/services_empty_state.dart';
import 'package:services/src/presentation/widgets/services_filter_bar.dart';
import 'package:services/src/routes/service_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// Provider services screen — Figma `4715:25922` (dashboard) and
/// `4715:23588` (empty state).
///
/// Real backend integration: provider services list
/// (`GET /provider-services`), overview (`GET /provider-services/overview`),
/// and the provider's own service requests (`GET /service-requests`).
/// Expects `ServicesListBloc`, `ServiceActionBloc`, `ServiceAnalyticsBloc`,
/// and `ServiceRequestsListBloc` above it in the tree (wired by
/// `ServicesModule`).
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

  /// Whether the empty-state layout (swapped background, hidden FAB, no
  /// segmented control) should show for the current tab/state combination.
  bool _showEmpty(ServicesListState state) =>
      _selectedTab == 0 &&
      state.status == RequestStatus.success &&
      state.services.isEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ServiceActionBloc, ServiceActionState>(
      listener: _handleActionState,
      child: BlocBuilder<ServicesListBloc, ServicesListState>(
        // The page chrome below (nav bar, FAB, segmented control vs. empty
        // state) only depends on `_showEmpty` — every other pagination emit
        // (load-more, loadingMore toggling, item updates) is irrelevant to
        // it. `_MyServicesContent` reads `ServicesListBloc` itself via its
        // own `BlocBuilder`, so it still rebuilds on every emit; only this
        // outer chrome is spared the redundant rebuilds.
        buildWhen: (previous, current) =>
            _showEmpty(previous) != _showEmpty(current),
        builder: (context, listState) {
          final isMyServices = _selectedTab == 0;
          final showEmpty = _showEmpty(listState);

          return Scaffold(
            backgroundColor: showEmpty ? colors.surface : colors.background,
            floatingActionButton: showEmpty
                ? null
                : AppFloatingActionButton(
                    onPressed: _onAddService,
                    semanticLabel: 'services.add_new_service'.tr(),
                  ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavBar(
                    title: 'services.title'.tr(),
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
                    const _DashboardHeader(),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      child: AppSegmentedControl<int>(
                        items: [
                          AppSegmentedControlItem(
                            value: 0,
                            label: 'services.tab_my_services'.tr(),
                          ),
                          AppSegmentedControlItem(
                            value: 1,
                            label: 'services.tab_service_request'.tr(),
                          ),
                        ],
                        selectedValue: _selectedTab,
                        onChanged: (index) =>
                            setState(() => _selectedTab = index),
                      ),
                    ),
                    Expanded(
                      child: isMyServices
                          ? _MyServicesContent(onAddService: _onAddService)
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
  const _DashboardHeader();

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.sm,
      ),
      child: Text(
        'services.dashboard'.tr(),
        style: typography.title3.copyWith(color: colors.textPrimary),
      ),
    );
  }
}

class _MyServicesContent extends StatefulWidget {
  const _MyServicesContent({required this.onAddService});

  final VoidCallback onAddService;

  @override
  State<_MyServicesContent> createState() => _MyServicesContentState();
}

class _MyServicesContentState extends State<_MyServicesContent> {
  late final _searchController = TextEditingController(
    text: context.read<ServicesListBloc>().state.searchQuery,
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onServiceTap(BuildContext context, ProviderServiceEntity service) {
    // Details page fetches the full service by id itself (GET
    // /provider-services/:id) rather than trusting this list row, which
    // carries only a subset of the fields (e.g. no requests/revenue).
    context.push(ServiceRoutes.detailsFor(service.id)).then((_) {
      if (!context.mounted) return;
      context.read<ServicesListBloc>().add(const ServicesListRefreshEvent());
    });
  }

  void _showStatusFilterSheet(
    BuildContext context,
    ProviderServiceStatus current,
  ) {
    final bloc = context.read<ServicesListBloc>();
    showAppActionSheet<void>(
      context: context,
      title: 'services.filter_status'.tr(),
      cancelLabel: 'services.cancel'.tr(),
      items: [
        for (final status in const [
          ProviderServiceStatus.all,
          ProviderServiceStatus.active,
          ProviderServiceStatus.inactive,
        ])
          AppActionSheetItem(
            label: _statusFilterLabel(status),
            onTap: () {
              if (status == current) return;
              bloc.add(ServicesListStatusChangedEvent(status));
            },
          ),
      ],
    );
  }

  static String _statusFilterLabel(ProviderServiceStatus status) =>
      switch (status) {
        ProviderServiceStatus.all => 'services.requests_filter_all'.tr(),
        ProviderServiceStatus.active => 'services.status_active'.tr(),
        ProviderServiceStatus.inactive => 'services.status_inactive'.tr(),
      };

  /// Realistic mock used only to skeletonize the real row via
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
    description: null,
    status: ProviderServiceStatus.active,
    images: const [],
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  @override
  Widget build(BuildContext context) {
    final onAddService = widget.onAddService;

    // Own `BlocBuilder` (rather than receiving state via a constructor
    // param) so this content rebuilds on every `ServicesListBloc` emit
    // independent of the parent page's chrome, which only rebuilds on the
    // rarer empty-state transition — see `_ProviderServicesPageState.build`.
    return BlocBuilder<ServicesListBloc, ServicesListState>(
      builder: (context, state) {
        // First-page load: skeletonize the *real* row widget with mock data
        // (no bespoke skeleton layout), matching the workers/invitations
        // convention.
        if (state.isLoading) {
          return AppSkeletonList(
            itemBuilder: (_, _) => ServiceListItem(service: _skeletonService),
          );
        }

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
                  const ServiceMetricsSection(),
                  SizedBox(height: AppSpacing.lg),
                  ServicesFilterBar(
                    searchController: _searchController,
                    onSearchChanged: (query) =>
                        context.read<ServicesListBloc>().add(
                          ServicesListSearchChangedEvent(query),
                        ),
                    statusLabel: state.statusFilter == ProviderServiceStatus.all
                        ? null
                        : _statusFilterLabel(state.statusFilter),
                    onStatusTap: () =>
                        _showStatusFilterSheet(context, state.statusFilter),
                    // Type has no backend query param to filter on (see
                    // ServicesFilterBar's doc comment) — intentionally left
                    // unwired; the dropdown stays visible but inert.
                  ),
                  SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () async => context.read<ServicesListBloc>().add(
                  const ServicesListRefreshEvent(),
                ),
                child: AppSwipeActionsGroup(
                  child: SanadPagedList<ProviderServiceEntity>(
                    state: toPagingState(state.pagination),
                    controller: MainNavScrollController.maybeOf(context),
                    // AppRefreshIndicator needs the child to always accept an
                    // overscroll drag — without this, a short list (few items)
                    // fights the refresh gesture with clamping physics.
                    physics: const AlwaysScrollableScrollPhysics(),
                    fetchNextPage: () => context.read<ServicesListBloc>().add(
                      const ServicesListLoadMoreEvent(),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      0,
                      AppSpacing.xl,
                      AppSpacing.xl,
                    ),
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, service, index) => ServiceListItem(
                      key: ValueKey(service.id),
                      service: service,
                      onTap: () => _onServiceTap(context, service),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => Center(
                      child: _ServicesErrorState(
                        failure: state.failure,
                        onRetry: () => context.read<ServicesListBloc>().add(
                          const ServicesListFetchEvent(),
                        ),
                      ),
                    ),
                    newPageErrorIndicatorBuilder: (_) => _NextPageErrorRetry(
                      onRetry: () => context.read<ServicesListBloc>().add(
                        const ServicesListLoadMoreEvent(),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: ServicesEmptyState(onAddService: onAddService),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
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

/// Server-side status filter for the Service Requests tab — Figma
/// `4749:20243`'s All/Review/Approved/Rejected chips, backed by
/// `GET /service-requests?status=`. Search likewise hits the server
/// (`?search=`), matching the requested service name.
class _ServiceRequestsContent extends StatefulWidget {
  const _ServiceRequestsContent();

  @override
  State<_ServiceRequestsContent> createState() =>
      _ServiceRequestsContentState();
}

class _ServiceRequestsContentState extends State<_ServiceRequestsContent> {
  late final _searchController = TextEditingController(
    text: context.read<ServiceRequestsListBloc>().state.searchQuery,
  );

  /// Realistic mock used only to skeletonize the real row via
  /// [AppSkeletonizer] — no bespoke skeleton widget.
  static final _skeletonRequest = ServiceRequestEntity(
    id: 'skeleton',
    name: BoneMock.words(3),
    unifiedRequestId: BoneMock.chars(8),
    category: CategoryRefEntity(
      id: 'skeleton',
      name: BoneMock.name,
      description: null,
    ),
    status: ServiceRequestStatus.underReview,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceRequestsListBloc, ServiceRequestsListState>(
      builder: (context, state) {
        // First-page load: skeletonize the *real* row widget with mock data
        // (no bespoke skeleton layout), matching the My Services tab.
        if (state.isLoading) {
          return AppSkeletonList(
            itemBuilder: (_, _) =>
                ServiceRequestListItem(request: _skeletonRequest),
          );
        }

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
                    onChanged: (value) => context
                        .read<ServiceRequestsListBloc>()
                        .add(ServiceRequestsListSearchChangedEvent(value)),
                  ),
                  SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final option in ServiceRequestStatus.values) ...[
                          AppChip(
                            label: _filterLabel(option),
                            selected: state.statusFilter == option,
                            onTap: () =>
                                context.read<ServiceRequestsListBloc>().add(
                                  ServiceRequestsListStatusChangedEvent(
                                    option,
                                  ),
                                ),
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
              child: AppRefreshIndicator(
                onRefresh: () async =>
                    context.read<ServiceRequestsListBloc>().add(
                      const ServiceRequestsListRefreshEvent(),
                    ),
                child: SanadPagedList<ServiceRequestEntity>(
                  state: toPagingState(state.pagination),
                  controller: MainNavScrollController.maybeOf(context),
                  // See the My Services list above — AlwaysScrollable keeps
                  // pull-to-refresh working on short lists.
                  physics: const AlwaysScrollableScrollPhysics(),
                  fetchNextPage: () =>
                      context.read<ServiceRequestsListBloc>().add(
                        const ServiceRequestsListLoadMoreEvent(),
                      ),
                  padding: EdgeInsets.all(AppSpacing.xl),
                  separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, request, index) =>
                      ServiceRequestListItem(
                        key: ValueKey(request.id),
                        request: request,
                        onTap: () => context.push(
                          ServiceRoutes.requestDetailsFor(request.id),
                          extra: request,
                        ),
                      ),
                  firstPageErrorIndicatorBuilder: (_) => Center(
                    child: _ServicesErrorState(
                      failure: state.failure,
                      onRetry: () =>
                          context.read<ServiceRequestsListBloc>().add(
                            const ServiceRequestsListFetchEvent(),
                          ),
                    ),
                  ),
                  newPageErrorIndicatorBuilder: (_) => _NextPageErrorRetry(
                    onRetry: () => context.read<ServiceRequestsListBloc>().add(
                      const ServiceRequestsListLoadMoreEvent(),
                    ),
                  ),
                  noItemsFoundIndicatorBuilder: (_) =>
                      const Center(child: ServiceRequestsEmptyState()),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  static String _filterLabel(ServiceRequestStatus status) => switch (status) {
    ServiceRequestStatus.all => 'services.requests_filter_all'.tr(),
    ServiceRequestStatus.underReview => 'services.requests_filter_review'.tr(),
    ServiceRequestStatus.approved => 'services.requests_filter_approved'.tr(),
    ServiceRequestStatus.rejected => 'services.requests_filter_rejected'.tr(),
  };
}

/// Compact "load more failed" footer shown by [SanadPagedList] in place of
/// the next-page loading indicator — keeps already-loaded rows visible
/// instead of replacing the whole list.
class _NextPageErrorRetry extends StatelessWidget {
  const _NextPageErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: GestureDetector(
          onTap: onRetry,
          behavior: HitTestBehavior.opaque,
          child: Text(
            failureRetryLabel(),
            style: context.appTypography.regularNormal.copyWith(
              color: context.appColors.link,
            ),
          ),
        ),
      ),
    );
  }
}
