import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
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
  const ProviderServicesPage({super.key});

  @override
  State<ProviderServicesPage> createState() => _ProviderServicesPageState();
}

class _ProviderServicesPageState extends State<ProviderServicesPage> {
  int _selectedTab = 0;

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

class _MyServicesContent extends StatelessWidget {
  const _MyServicesContent({required this.state, required this.onAddService});

  final ServicesListState state;
  final VoidCallback onAddService;

  @override
  Widget build(BuildContext context) {
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
            const ServicesFilterBar(),
            SizedBox(height: AppSpacing.xl),
            ...state.services.map(
              (service) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.xl),
                child: ServiceProviderCard(
                  data: ProviderServiceCardData.fromEntity(service),
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

class _ServiceRequestsContent extends StatelessWidget {
  const _ServiceRequestsContent();

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

        return AppRefreshIndicator(
          onRefresh: () async => context.read<ServiceRequestsListBloc>().add(
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
              itemCount: state.requests.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                if (index >= state.requests.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: AppLoadingIndicator()),
                  );
                }
                return ServiceRequestListItem(request: state.requests[index]);
              },
            ),
          ),
        );
      },
    );
  }
}
