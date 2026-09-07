import 'dart:async';

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
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:storage/storage.dart';

/// Provider services screen — Figma `4715:25922` (dashboard) and
/// `4715:23588` (empty state).
///
/// Real backend integration: provider services list
/// (`GET /provider-services`), overview (`GET /provider-services/overview`),
/// and the provider's own service requests (`GET /service-requests`).
/// Expects `ServicesListBloc` and `ServiceActionBloc` above it in the tree
/// always; `ServiceAnalyticsBloc` and `ServiceRequestsListBloc` only when
/// [isOwner] is true — both endpoints 403 for a worker/manager token
/// regardless of granted permissions, so `ServicesModule.shellRoute()` does
/// not provide those two blocs at all when [isOwner] is false. Reading
/// either one here would be a bug, not a fallback case.
class ProviderServicesPage extends StatefulWidget {
  /// Creates the provider services dashboard / empty-state screen.
  ///
  /// [initialTab] lets the Request-Submitted success popover land directly
  /// on the Service Requests tab (`1`) via `context.go(ServiceRoutes.list,
  /// extra: 1)`; defaults to My Services (`0`) and is ignored when [isOwner]
  /// is false, since tab `1` does not exist for a non-owner.
  const ProviderServicesPage({
    required this.isOwner,
    super.key,
    this.initialTab = 0,
  });

  final int initialTab;

  /// Whether the signed-in account may see the owner-only performance
  /// metrics and Service Requests tab — see the class doc comment.
  final bool isOwner;

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  // Ephemeral UI-only state (which tab is showing) — `ValueNotifier` +
  // `ValueListenableBuilder` instead of `setState`, per this package's
  // zero-`setState` architecture rule.
  late final ValueNotifier<int> _selectedTab = ValueNotifier(
    widget.isOwner ? widget.initialTab : 0,
  );

  @override
  void initState() {
    super.initState();
    context.read<ServicesListBloc>().add(const ServicesListFetchEvent());
    if (widget.isOwner) {
      context.read<ServiceAnalyticsBloc>().add(
        const ServiceAnalyticsFetchEvent(),
      );
      context.read<ServiceRequestsListBloc>().add(
        const ServiceRequestsListFetchEvent(),
      );
    }
  }

  @override
  void dispose() {
    _selectedTab.dispose();
    super.dispose();
  }

  /// Whether the full onboarding empty-state layout (swapped background,
  /// hidden FAB, no segmented control/search bar) should show for the
  /// current tab/state combination.
  ///
  /// Only true when the provider genuinely has zero services — an active
  /// search query or status filter narrowing the *current* page to zero
  /// results must NOT trigger this (SAN-580): that's a "no results found"
  /// case, handled in-list by `noItemsFoundIndicatorBuilder` below, which
  /// keeps the search bar/segmented control visible and gives the user a
  /// way back (clear search / change filter) instead of hiding them.
  bool _showEmpty(ServicesListState state, int selectedTab) =>
      selectedTab == 0 &&
      state.status == RequestStatus.success &&
      state.services.isEmpty &&
      state.searchQuery.trim().isEmpty &&
      state.statusFilter == ProviderServiceStatus.all &&
      state.selectedCategoryId == null;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return BlocListener<ServiceActionBloc, ServiceActionState>(
      listener: _handleActionState,
      child: ValueListenableBuilder<int>(
        valueListenable: _selectedTab,
        builder: (context, selectedTab, _) =>
            BlocBuilder<ServicesListBloc, ServicesListState>(
              // The page chrome below (nav bar, FAB, segmented control vs.
              // empty state) only depends on `_showEmpty` — every other
              // pagination emit (load-more, loadingMore toggling, item
              // updates) is irrelevant to it. `_MyServicesContent` reads
              // `ServicesListBloc` itself via its own `BlocBuilder`, so it
              // still rebuilds on every emit; only this outer chrome is
              // spared the redundant rebuilds.
              buildWhen: (previous, current) =>
                  _showEmpty(previous, selectedTab) !=
                  _showEmpty(current, selectedTab),
              builder: (context, listState) {
                final isMyServices = selectedTab == 0;
                final showEmpty = _showEmpty(listState, selectedTab);

                return Scaffold(
                  backgroundColor: showEmpty
                      ? colors.surface
                      : colors.background,
                  // The pinned search field sits near the top of the sliver
                  // list, never under the keyboard, so there's nothing here
                  // that needs the body to shrink for it. Left at the
                  // default (true), Scaffold's built-in FAB-follows-keyboard
                  // behavior lifts the FAB by the keyboard's height on focus
                  // — landing it mid-list instead of "anchored" (SAN-580).
                  resizeToAvoidBottomInset: false,
                  // Add Service (`POST /provider-services`) is owner-only
                  // (RBAC Phase 7 finding G3 — no create permission exists,
                  // so a persona check is the only correct client gate).
                  // The route itself already bounces non-owners home, but
                  // rendering the FAB to bounce on tap violates the plan's
                  // rule against "reveal-then-bounce" affordances.
                  floatingActionButton: (showEmpty || !widget.isOwner)
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
                            child: ServicesEmptyState(
                              // Non-owners see the empty-state layout too,
                              // but with the "Add first service" CTA
                              // omitted — same G3 gate as the FAB above.
                              // `ServicesEmptyState.onAddService` is
                              // nullable and hides the button when null.
                              onAddService: widget.isOwner
                                  ? _onAddService
                                  : null,
                            ),
                          ),
                        ] else ...[
                          // `_DashboardHeader` used to sit here, above the
                          // segment — it now lives inside
                          // `_MyServicesContent`'s collapsing header sliver
                          // (see the class doc comment) so it scrolls away
                          // with the rest of the analytics/filter chrome
                          // instead of staying fixed page-level chrome.
                          // No segmented control at all when the account
                          // isn't an owner: `_ServiceRequestsContent`'s bloc
                          // isn't provided in this case (see
                          // `ServicesModule.shellRoute`), so there is
                          // deliberately nothing to switch to.
                          if (widget.isOwner)
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
                                selectedValue: selectedTab,
                                onChanged: (index) =>
                                    _selectedTab.value = index,
                              ),
                            ),
                          Expanded(
                            child: isMyServices
                                ? _MyServicesContent(
                                    showAnalytics: widget.isOwner,
                                    isOwner: widget.isOwner,
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

/// Fixed-height pinned sliver header — keeps [child] (the search field, for
/// both tabs) visible while the collapsing sliver above it (analytics,
/// dashboard title, status/type filters, or status chips) scrolls away.
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _PinnedHeaderDelegate({required this.height, required this.child});

  final double height;
  final Widget child;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) => child;

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) =>
      oldDelegate.height != height || oldDelegate.child != child;
}

/// Height of the pinned search header — matches [AppSearchField]'s actual
/// rendered height (`AppDimension.fieldHeightMd`, not `FieldTokens
/// .fieldHeight` — a bordered search field is styled from
/// `SearchBarStyleSpec.height`, a separate, smaller token) plus its
/// vertical padding. Must be exact: unlike `SliverAppBar.bottom`'s
/// `PreferredSize` (used by `ProviderBranchesPage`), which tolerates a
/// mismatch as harmless empty space, `SliverPersistentHeader` hard-asserts
/// that its child's rendered height matches `minExtent`/`maxExtent`.
double _searchHeaderHeight() =>
    AppDimension.fieldHeightMd + (responsiveSpacing(10) * 2);

/// Sliver-native replacement for [AppSkeletonList] for embedding first-page
/// loading placeholders directly inside a [CustomScrollView] alongside other
/// slivers — [AppSkeletonList] wraps a plain (non-shrink-wrapped) [ListView],
/// which cannot be nested inside another scroll view.
class _SkeletonSliverList extends StatelessWidget {
  const _SkeletonSliverList({required this.itemBuilder, this.padding});

  /// Number of placeholder rows — matches [AppSkeletonList]'s own default.
  static const _itemCount = 6;

  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AppSkeletonizer.sliver(
      enabled: true,
      child: SliverPadding(
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              AppSpacing.xl,
              0,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
        sliver: SliverList.separated(
          itemCount: _itemCount,
          separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
          itemBuilder: itemBuilder,
        ),
      ),
    );
  }
}

class _MyServicesContent extends StatefulWidget {
  const _MyServicesContent({
    required this.showAnalytics,
    required this.isOwner,
  });

  /// Whether to render [ServiceMetricsSection] — `false` when the account
  /// isn't an owner, since `ServiceAnalyticsBloc` isn't provided in that
  /// case (see `ServicesModule.shellRoute`) and the section would otherwise
  /// throw looking it up.
  final bool showAnalytics;

  /// Whether the row-level swipe actions (Edit / Pause-Resume / Delete) are
  /// shown (RBAC Phase 7L — all owner-only mutations per finding G3).
  final bool isOwner;

  @override
  State<_MyServicesContent> createState() => _MyServicesContentState();
}

class _MyServicesContentState extends State<_MyServicesContent> {
  late final _searchController = TextEditingController(
    text: context.read<ServicesListBloc>().state.searchQuery,
  );

  /// `null` while the Hive read is in flight — the hint never arms until
  /// this resolves, so it can't briefly play before we know it's been seen.
  bool? _hintSeen;

  /// One-shot latch: once the hint has fired (played or been cancelled), row
  /// 0 renders as a plain `ServiceListItem` on every later build (filter
  /// change, refresh) instead of re-wrapping it in `AppSwipeActionHint`.
  bool _hintAttempted = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadHintSeen());
  }

  Future<void> _loadHintSeen() async {
    final seen =
        await sl<HiveLocalStorage>().load(
              key: StorageKeys.servicesSwipeHintSeen,
              boxName: HiveBoxes.defaultBox,
            )
            as bool? ??
        false;
    if (!mounted) return;
    setState(() => _hintSeen = seen);
  }

  /// Only the first row, and only once — [_hintSeen] resolves to `false`
  /// (never shown before) and [_hintAttempted] hasn't already latched from
  /// this row having played or been cancelled.
  bool _showSwipeHintFor(int index) =>
      index == 0 && _hintSeen == false && !_hintAttempted;

  void _markHintShown() {
    if (!mounted) return;
    setState(() {
      _hintSeen = true;
      _hintAttempted = true;
    });
    unawaited(
      sl<HiveLocalStorage>().save(
        key: StorageKeys.servicesSwipeHintSeen,
        value: true,
        boxName: HiveBoxes.defaultBox,
      ),
    );
  }

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
    SheetNavigator.push<void>(
      context,
      AppActionList(
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
      ),
      settings: SheetRouteSettings(
        title: 'services.filter_status'.tr(),
        padChild: false,
      ),
    );
  }

  static String _statusFilterLabel(ProviderServiceStatus status) =>
      switch (status) {
        ProviderServiceStatus.all => 'services.requests_filter_all'.tr(),
        ProviderServiceStatus.active => 'services.status_active'.tr(),
        ProviderServiceStatus.inactive => 'services.status_inactive'.tr(),
      };

  /// Options come from [ServicesListState.categoryOptions] — the categories
  /// present in the currently-loaded `provider-services` page, not a
  /// separate categories catalog (see the class doc comment on
  /// `ServicesListBloc`).
  void _showCategoryFilterSheet(
    BuildContext context,
    List<CategoryRefEntity> categories,
    String? selectedCategoryId,
  ) {
    final bloc = context.read<ServicesListBloc>();
    SheetNavigator.push<void>(
      context,
      AppActionList(
        items: [
          AppActionSheetItem(
            label: 'services.requests_filter_all'.tr(),
            onTap: () {
              if (selectedCategoryId == null) return;
              bloc.add(const ServicesListCategoryChangedEvent(null));
            },
          ),
          for (final category in categories)
            AppActionSheetItem(
              label: category.name,
              onTap: () {
                if (category.id == selectedCategoryId) return;
                bloc.add(ServicesListCategoryChangedEvent(category.id));
              },
            ),
        ],
      ),
      settings: SheetRouteSettings(
        title: 'services.filter_category'.tr(),
        padChild: false,
      ),
    );
  }

  static String? _categoryFilterLabel(ServicesListState state) {
    final selectedId = state.selectedCategoryId;
    if (selectedId == null) return null;
    for (final category in state.categoryOptions) {
      if (category.id == selectedId) return category.name;
    }
    return null;
  }

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
    // Own `BlocBuilder` (rather than receiving state via a constructor
    // param) so this content rebuilds on every `ServicesListBloc` emit
    // independent of the parent page's chrome, which only rebuilds on the
    // rarer empty-state transition — see `_ProviderServicesPageState.build`.
    return BlocBuilder<ServicesListBloc, ServicesListState>(
      builder: (context, state) {
        // Collapsing-header layout: the Dashboard title, analytics and
        // status/type filters live in a `SliverToBoxAdapter` (first sliver
        // below) so they scroll away with the list; the search field is a
        // pinned `SliverPersistentHeader` so it — and the segmented control
        // above it, which is the parent page's own fixed chrome — stay
        // visible while scrolling. Search/filter chrome renders
        // unconditionally on the very first load AND on any filter-changed
        // reload (both set the same `state.isLoading` flag); only the
        // list/cards sliver below skeletonizes.
        return AppRefreshIndicator(
          onRefresh: () async => context.read<ServicesListBloc>().add(
            const ServicesListRefreshEvent(),
          ),
          child: AppSwipeActionsGroup(
            child: CustomScrollView(
              controller: MainNavScrollController.maybeOf(context),
              // AppRefreshIndicator needs the child to always accept an
              // overscroll drag — without this, a short list (few items)
              // fights the refresh gesture with clamping physics.
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _DashboardHeader(),
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.xl,
                          AppSpacing.md,
                          AppSpacing.xl,
                          AppSpacing.md,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (widget.showAnalytics) ...[
                              const ServiceMetricsSection(),
                              SizedBox(height: AppSpacing.lg),
                            ],
                            ServicesFilterBar(
                              showSearch: false,
                              statusLabel:
                                  state.statusFilter ==
                                      ProviderServiceStatus.all
                                  ? null
                                  : _statusFilterLabel(state.statusFilter),
                              onStatusTap: () => _showStatusFilterSheet(
                                context,
                                state.statusFilter,
                              ),
                              categoryLabel: _categoryFilterLabel(state),
                              onCategoryTap: () => _showCategoryFilterSheet(
                                context,
                                state.categoryOptions,
                                state.selectedCategoryId,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedHeaderDelegate(
                    height: _searchHeaderHeight(),
                    child: ColoredBox(
                      color: context.appColors.background,
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.xl,
                          vertical: responsiveSpacing(10),
                        ),
                        child: AppSearchField(
                          controller: _searchController,
                          variant: AppSearchFieldVariant.bordered,
                          hint: 'services.search_hint'.tr(),
                          showMicIcon: false,
                          onChanged: (query) =>
                              context.read<ServicesListBloc>().add(
                                ServicesListSearchChangedEvent(query),
                              ),
                        ),
                      ),
                    ),
                  ),
                ),
                // First-page load or a filter-changed reload: skeletonize
                // the *real* row widget with mock data (no bespoke skeleton
                // layout), matching the workers/invitations convention —
                // scoped to just this sliver, not the chrome above.
                if (state.isLoading)
                  _SkeletonSliverList(
                    itemBuilder: (_, _) =>
                        ServiceListItem(service: _skeletonService),
                  )
                else
                  SanadPagedSliverList<ProviderServiceEntity>(
                    // Category is a client-side filter over the already
                    // -loaded page — swap in `filteredServices` here rather
                    // than in the BLoC's own `pagination`, so `hasMore` /
                    // `loadingMore` / load-more dispatch above keep driving
                    // off the real, unfiltered accumulated state.
                    state: toPagingState(
                      state.pagination.copyWith(
                        items: state.filteredServices,
                      ),
                    ),
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
                    itemBuilder: (context, service, index) =>
                        _showSwipeHintFor(index)
                        ? AppSwipeActionHint(
                            enabled: true,
                            onShown: _markHintShown,
                            builder: (context, controller) => ServiceListItem(
                              key: ValueKey(service.id),
                              service: service,
                              isOwner: widget.isOwner,
                              onTap: () => _onServiceTap(context, service),
                              hintController: controller,
                            ),
                          )
                        : ServiceListItem(
                            key: ValueKey(service.id),
                            service: service,
                            isOwner: widget.isOwner,
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
                    // Reached only when a search query, status filter, or
                    // category filter is active and narrows the current page
                    // to zero results — `_showEmpty` above owns the true
                    // "provider has zero services at all" case, so there is
                    // always at least one real service here and the
                    // onboarding "Add first service" CTA never belongs
                    // (SAN-580).
                    noItemsFoundIndicatorBuilder: (_) => Center(
                      child: state.searchQuery.trim().isNotEmpty
                          ? ServicesSearchEmptyState(
                              query: state.searchQuery,
                              onClearSearch: () {
                                _searchController.clear();
                                context.read<ServicesListBloc>().add(
                                  const ServicesListSearchChangedEvent(''),
                                );
                              },
                            )
                          : state.selectedCategoryId != null
                          ? ServicesCategoryEmptyState(
                              onClearCategory: () =>
                                  context.read<ServicesListBloc>().add(
                                    const ServicesListCategoryChangedEvent(
                                      null,
                                    ),
                                  ),
                            )
                          : const ServicesEmptyState(),
                    ),
                  ),
              ],
            ),
          ),
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
        // Collapsing-header layout mirroring `_MyServicesContent`: the
        // status chips collapse away with the rest of the header, the
        // search field is a pinned `SliverPersistentHeader`. Chrome renders
        // unconditionally (see that class's build for why); only the
        // list/cards sliver below skeletonizes on first load.
        return AppRefreshIndicator(
          onRefresh: () async => context.read<ServiceRequestsListBloc>().add(
            const ServiceRequestsListRefreshEvent(),
          ),
          child: CustomScrollView(
            controller: MainNavScrollController.maybeOf(context),
            // See the My Services list above — AlwaysScrollable keeps
            // pull-to-refresh working on short lists.
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.xl,
                    AppSpacing.md,
                    AppSpacing.xl,
                    AppSpacing.sm,
                  ),
                  child: SingleChildScrollView(
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
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _PinnedHeaderDelegate(
                  height: _searchHeaderHeight(),
                  child: ColoredBox(
                    color: context.appColors.background,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl,
                        vertical: responsiveSpacing(10),
                      ),
                      child: AppSearchField(
                        controller: _searchController,
                        variant: AppSearchFieldVariant.bordered,
                        hint: 'services.search_hint'.tr(),
                        showMicIcon: false,
                        onChanged: (value) => context
                            .read<ServiceRequestsListBloc>()
                            .add(ServiceRequestsListSearchChangedEvent(value)),
                      ),
                    ),
                  ),
                ),
              ),
              // First-page load: skeletonize the *real* row widget with mock
              // data (no bespoke skeleton layout), matching the My Services
              // tab.
              if (state.isLoading)
                _SkeletonSliverList(
                  padding: EdgeInsets.all(AppSpacing.xl),
                  itemBuilder: (_, _) =>
                      ServiceRequestListItem(request: _skeletonRequest),
                )
              else
                SanadPagedSliverList<ServiceRequestEntity>(
                  state: toPagingState(state.pagination),
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
            ],
          ),
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

/// Compact "load more failed" footer shown by [SanadPagedSliverList] in
/// place of the next-page loading indicator — keeps already-loaded rows
/// visible instead of replacing the whole list.
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
