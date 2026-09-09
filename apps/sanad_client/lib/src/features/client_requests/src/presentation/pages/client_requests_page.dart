import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:requests_core/requests_core.dart';
import 'package:sanad_client/src/features/client_requests/src/domain/entities/client_request.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_date_time_picker.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/widgets/request_status_badge.dart';
import 'package:sanad_client/src/features/client_requests/src/routes/client_request_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// The client's own requests.
///
/// Re-reads on every visit and on pull-to-refresh. That is deliberate rather
/// than lazy: the backend moves requests on timers — a submitted request
/// expires, a scheduled one starts, an awaiting-confirmation one completes —
/// so a list held from a previous visit is routinely stale, and mobile does not
/// subscribe to the notification stream.
class ClientRequestsPage extends StatelessWidget {
  /// Creates the page.
  const ClientRequestsPage({required this.buildBloc, super.key});

  /// Builds the list bloc. Injected so the page stays testable.
  final ClientRequestsListBloc Function() buildBloc;

  @override
  Widget build(BuildContext context) => BlocProvider<ClientRequestsListBloc>(
    create: (_) => buildBloc()..add(const ClientRequestsStarted()),
    child: const _ClientRequestsView(),
  );
}

class _ClientRequestsView extends StatelessWidget {
  const _ClientRequestsView();

  /// The statuses worth offering as a filter. Not every value: `unknown` is a
  /// parse sentinel, and the rest are rare enough to live under "All".
  static const List<ClientRequestStatus?> _filters = [
    null,
    ClientRequestStatus.draft,
    ClientRequestStatus.submitted,
    ClientRequestStatus.scheduled,
    ClientRequestStatus.inProgress,
    ClientRequestStatus.awaitingConfirmation,
    ClientRequestStatus.completed,
  ];

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ClientRequestsListBloc>();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push<void>(ClientRequestRoutes.compose);
          if (context.mounted) bloc.add(const ClientRequestsRefreshed());
        },
        label: Text('client_requests.new_request'.tr()),
        icon: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            AppNavBar(title: 'client_requests.title'.tr()),
            const _FilterBar(filters: _filters),
            Expanded(
              child:
                  BlocBuilder<ClientRequestsListBloc, ClientRequestsListState>(
                    builder: (context, state) => AppRefreshIndicator(
                      onRefresh: () async =>
                          bloc.add(const ClientRequestsRefreshed()),
                      child: SanadPagedList<ClientRequest>(
                        state: toPagingState(state.data),
                        fetchNextPage: () =>
                            bloc.add(const ClientRequestsNextPageRequested()),
                        padding: EdgeInsets.all(AppSpacing.lg),
                        itemBuilder: (context, request, _) => _RequestRow(
                          request: request,
                          onTap: () async {
                            await context.push<void>(
                              ClientRequestRoutes.detail(request.id),
                            );
                            // The detail screen can cancel, confirm or book
                            // the request, and a timer can move it while it
                            // is open.
                            if (context.mounted) {
                              bloc.add(const ClientRequestsRefreshed());
                            }
                          },
                        ),
                        separatorBuilder: (_, _) =>
                            SizedBox(height: AppSpacing.md),
                        firstPageErrorIndicatorBuilder: (context) =>
                            AppGenericEmptyState(
                              title: 'client_requests.error_title'.tr(),
                              description:
                                  state.data.firstPageError
                                      ?.localizedSafeMessage() ??
                                  '',
                            ),
                        newPageErrorIndicatorBuilder: (context) => Padding(
                          padding: EdgeInsets.all(AppSpacing.md),
                          child: Center(
                            child: AppButton(
                              label: 'client_requests.retry'.tr(),
                              onPressed: () => bloc.add(
                                const ClientRequestsNextPageRequested(),
                              ),
                              variant: AppButtonVariant.outline,
                              size: AppButtonSize.small,
                            ),
                          ),
                        ),
                        noItemsFoundIndicatorBuilder: (context) =>
                            AppGenericEmptyState(
                              title: 'client_requests.empty_title'.tr(),
                              description: 'client_requests.empty_description'
                                  .tr(),
                            ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.filters});

  final List<ClientRequestStatus?> filters;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<ClientRequestsListBloc, ClientRequestsListState>(
        buildWhen: (a, b) => a.statusFilter != b.statusFilter,
        builder: (context, state) => SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            itemCount: filters.length,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final status = filters[index];
              return Center(
                child: AppChip(
                  label: status == null
                      ? 'client_requests.filter_all'.tr()
                      : status.labelKey.tr(),
                  selected: state.statusFilter == status,
                  // The filter is applied server-side: filtering a loaded page
                  // would show an arbitrary subset of the matches.
                  onTap: () => context.read<ClientRequestsListBloc>().add(
                    ClientRequestsFilterChanged(status),
                  ),
                ),
              );
            },
          ),
        ),
      );
}

class _RequestRow extends StatelessWidget {
  const _RequestRow({required this.request, required this.onTap});

  final ClientRequest request;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final preferredAt = request.preferredAt;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.slate200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    // A draft may have no service yet, which is legitimate —
                    // the placeholder says so rather than rendering blank.
                    request.serviceName ??
                        'client_requests.service_placeholder'.tr(),
                    style: typography.titleSmall,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                RequestStatusBadge(status: request.status),
              ],
            ),
            if (request.areaName != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                request.areaName!,
                style: typography.bodySmall.copyWith(color: colors.slate600),
              ),
            ],
            if (preferredAt != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                formatRequestDateTime(context, preferredAt),
                style: typography.labelSmall.copyWith(color: colors.slate500),
              ),
            ],
            if (request.offerCount > 0) ...[
              SizedBox(height: AppSpacing.sm),
              AppChip(
                label: 'client_requests.offer_count'.tr(
                  namedArgs: {'count': '${request.offerCount}'},
                ),
                tone: AppChipTone.softSuccess,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
