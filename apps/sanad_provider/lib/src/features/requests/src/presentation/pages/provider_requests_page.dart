import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:sanad_provider/src/features/requests/src/domain/entities/provider_request.dart';
import 'package:sanad_provider/src/features/requests/src/domain/enums/provider_request_tab.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/bloc/workspace/provider_requests_workspace_bloc.dart';
import 'package:sanad_provider/src/features/requests/src/presentation/widgets/provider_request_formats.dart';
import 'package:sanad_provider/src/features/requests/src/routes/provider_request_routes.dart';
import 'package:shared_ui/shared_ui.dart';

/// The provider request workspace.
///
/// Tabs, badge counts and the four headline numbers all come from the server.
/// Nothing here buckets a request locally — the tab depends on this provider's
/// own offer thread as well as the request status, and the counts describe the
/// whole feed rather than the loaded page.
class ProviderRequestsPage extends StatelessWidget {
  /// Creates the workspace.
  const ProviderRequestsPage({required this.buildBloc, super.key});

  /// Builds the workspace bloc.
  final ProviderRequestsWorkspaceBloc Function() buildBloc;

  @override
  Widget build(BuildContext context) =>
      BlocProvider<ProviderRequestsWorkspaceBloc>(
        create: (_) => buildBloc()..add(const ProviderWorkspaceStarted()),
        child: const _WorkspaceView(),
      );
}

class _WorkspaceView extends StatefulWidget {
  const _WorkspaceView();

  @override
  State<_WorkspaceView> createState() => _WorkspaceViewState();
}

class _WorkspaceViewState extends State<_WorkspaceView>
    with WidgetsBindingObserver {
  final TextEditingController _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Requests expire, start and auto-complete on server timers while the app
    // is backgrounded. Resuming is the moment to re-read rather than trust a
    // feed assembled minutes ago.
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<ProviderRequestsWorkspaceBloc>().add(
        const ProviderWorkspaceRefreshed(),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProviderRequestsWorkspaceBloc>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppNavBar(title: 'provider_requests.title'.tr()),
        Padding(
          padding: EdgeInsetsDirectional.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: AppSearchField(
            controller: _search,
            hint: 'provider_requests.search_placeholder'.tr(),
            showMicIcon: false,
            onChanged: (value) =>
                bloc.add(ProviderWorkspaceSearchChanged(value)),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        const _StatsRow(),
        const _TabBar(),
        Expanded(
          child:
              BlocBuilder<
                ProviderRequestsWorkspaceBloc,
                ProviderRequestsWorkspaceState
              >(
                builder: (context, state) => AppRefreshIndicator(
                  onRefresh: () async =>
                      bloc.add(const ProviderWorkspaceRefreshed()),
                  child: SanadPagedList<ProviderRequest>(
                    state: toPagingState(state.data),
                    fetchNextPage: () =>
                        bloc.add(const ProviderWorkspaceNextPageRequested()),
                    padding: EdgeInsets.all(AppSpacing.lg),
                    itemBuilder: (context, request, _) => _RequestRow(
                      request: request,
                      onTap: () async {
                        await context.push<void>(
                          ProviderRequestRoutes.detail(request.id),
                        );
                        // The detail screen can offer, withdraw, book, complete
                        // or cancel — every one of which moves this row to a
                        // different tab and changes the counts.
                        if (context.mounted) {
                          bloc.add(const ProviderWorkspaceRefreshed());
                        }
                      },
                    ),
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.md),
                    firstPageErrorIndicatorBuilder: (context) =>
                        AppGenericEmptyState(
                          title: 'provider_requests.error_title'.tr(),
                          description:
                              state.data.firstPageError
                                  ?.localizedSafeMessage() ??
                              '',
                        ),
                    newPageErrorIndicatorBuilder: (context) => Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(
                        child: AppButton(
                          label: 'provider_requests.retry'.tr(),
                          onPressed: () => bloc.add(
                            const ProviderWorkspaceNextPageRequested(),
                          ),
                          variant: AppButtonVariant.outline,
                          size: AppButtonSize.small,
                        ),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (context) =>
                        AppGenericEmptyState(
                          title: 'provider_requests.empty_title'.tr(),
                          description: 'provider_requests.empty_description'
                              .tr(),
                        ),
                  ),
                ),
              ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        ProviderRequestsWorkspaceBloc,
        ProviderRequestsWorkspaceState
      >(
        buildWhen: (a, b) => a.stats != b.stats,
        builder: (context, state) {
          final stats = state.stats;
          return SizedBox(
            height: 72,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.lg,
              ),
              children: [
                _StatTile(
                  label: 'provider_requests.stats.needs_your_offer'.tr(),
                  value: stats.needsYourOffer,
                ),
                _StatTile(
                  label: 'provider_requests.stats.awaiting_client'.tr(),
                  value: stats.awaitingClient,
                ),
                _StatTile(
                  label: 'provider_requests.stats.scheduled_today'.tr(),
                  value: stats.scheduledToday,
                ),
                _StatTile(
                  label: 'provider_requests.stats.completed_this_month'.tr(),
                  value: stats.completedThisMonth,
                ),
              ],
            ),
          );
        },
      );
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: 140,
      margin: EdgeInsetsDirectional.only(end: AppSpacing.sm),
      padding: EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.slate50,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('$value', style: typography.title3),
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typography.labelSmall.copyWith(color: colors.slate600),
          ),
        ],
      ),
    );
  }
}

class _TabBar extends StatelessWidget {
  const _TabBar();

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<
        ProviderRequestsWorkspaceBloc,
        ProviderRequestsWorkspaceState
      >(
        buildWhen: (a, b) => a.tab != b.tab || a.counts != b.counts,
        builder: (context, state) => SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsetsDirectional.symmetric(
              horizontal: AppSpacing.lg,
            ),
            itemCount: ProviderRequestTab.ordered.length,
            separatorBuilder: (_, _) => SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final tab = ProviderRequestTab.ordered[index];
              final count = state.counts.of(tab);
              return Center(
                child: AppChip(
                  // The badge count is the server's, for the whole feed — not
                  // a count of the rows currently loaded.
                  label: count > 0
                      ? '${tab.labelKey.tr()} ($count)'
                      : tab.labelKey.tr(),
                  selected: state.tab == tab,
                  onTap: () =>
                      context.read<ProviderRequestsWorkspaceBloc>().add(
                        ProviderWorkspaceTabChanged(
                          state.tab == tab ? null : tab,
                        ),
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

  final ProviderRequest request;
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
                    request.serviceName,
                    style: typography.titleSmall,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                // The tab as the server assigned it — a compact restatement of
                // where this row lives, useful when no tab filter is active.
                AppChip(label: request.tab.labelKey.tr()),
              ],
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              [
                // Only the area, never the street: that is withheld until the
                // booking is won.
                if (request.areaName != null) request.areaName!,
                'provider_requests.distance_km'.tr(
                  namedArgs: {'km': request.distanceKm.toStringAsFixed(1)},
                ),
              ].join(' · '),
              style: typography.bodySmall.copyWith(color: colors.slate600),
            ),
            if (preferredAt != null) ...[
              SizedBox(height: AppSpacing.xs),
              Text(
                formatProviderDateTime(context, preferredAt),
                style: typography.labelSmall.copyWith(color: colors.slate500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
