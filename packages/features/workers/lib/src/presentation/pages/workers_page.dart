import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
import 'package:workers/src/presentation/widgets/invitations_content.dart';
import 'package:workers/src/presentation/widgets/worker_empty_states.dart';
import 'package:workers/src/presentation/widgets/worker_list_item.dart';
import 'package:workers/src/presentation/widgets/worker_search_sheet.dart';
import 'package:workers/src/routes/worker_routes.dart';

/// Figma `team` / `team-empty-state` / search sheet (`1526:12186`,
/// `1526:12093`, `1526:12837`).
class WorkersPage extends StatefulWidget {
  const WorkersPage({super.key});

  @override
  State<WorkersPage> createState() => _WorkersPageState();
}

class _WorkersPageState extends State<WorkersPage> {
  @override
  void initState() {
    super.initState();
    context.read<WorkersBloc>().add(const WorkersFetchEvent());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: BlocListener<WorkersBloc, WorkersState>(
          listenWhen: (previous, current) =>
              previous.actionFailure != current.actionFailure &&
              current.actionFailure != null,
          listener: (context, state) {
            final message = state.actionFailure!.message.trim();
            final title = message.isEmpty
                ? 'workers.action_failed'.tr()
                : message.contains(' ')
                ? message
                : message.tr();
            showAppSnackbar(context: context, title: title);
            context.read<WorkersBloc>().add(
              const WorkerActionFailureClearedEvent(),
            );
          },
          child: BlocBuilder<WorkersBloc, WorkersState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppNavBar(
                    title: 'workers.title'.tr(),
                    showBackButton: true,
                    trailing: AppNotificationIcon(onTap: () {}),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    child: AppSegmentedControl(
                      segments: [
                        'workers.tab_team'.tr(),
                        'workers.tab_invitations'.tr(),
                      ],
                      selectedIndex: state.selectedTab,
                      onChanged: (index) => context.read<WorkersBloc>().add(
                        WorkersTabChangedEvent(index),
                      ),
                    ),
                  ),
                  Expanded(
                    child: state.isTeamTab
                        ? _WorkersContent(state: state)
                        : InvitationsContent(state: state),
                  ),
                  _FooterButton(isLoading: state.isLoading),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _WorkersContent extends StatelessWidget {
  const _WorkersContent({required this.state});

  final WorkersState state;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const ShimmerListSkeleton();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppSearchField(
            hint: 'workers.search_hint'.tr(),
            showMicIcon: false,
            readOnly: true,
            onTap: () => showWorkerSearchSheet(
              context,
              scope: WorkerSearchScope.team,
            ),
          ),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              context.read<WorkersBloc>().add(const WorkersRefreshEvent());
            },
            child: state.hasError && state.workers.isEmpty
                ? AppFillRemainingScrollable(
                    child: _ErrorState(
                      failure: state.failure,
                      onRetry: () => context.read<WorkersBloc>().add(
                        const WorkersRefreshEvent(),
                      ),
                    ),
                  )
                : state.filteredWorkers.isEmpty
                ? AppFillRemainingScrollable(
                    child: _EmptyState(),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                              notification.metrics.maxScrollExtent - 200 &&
                          state.workersHasMore &&
                          !state.workersLoadingMore) {
                        context.read<WorkersBloc>().add(
                          const WorkersLoadMoreEvent(),
                        );
                      }
                      return false;
                    },
                    child: ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        left: AppSpacing.lg,
                        right: AppSpacing.lg,
                        bottom: AppSpacing.lg,
                      ),
                      itemCount:
                          state.filteredWorkers.length +
                          (state.workersLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          SizedBox(height: AppSpacing.sm),
                      itemBuilder: (context, index) {
                        if (index >= state.filteredWorkers.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(child: AppLoadingIndicator()),
                          );
                        }
                        return WorkerListItem(
                          worker: state.filteredWorkers[index],
                        );
                      },
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.isLoading});

  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: AppButton(
        label: 'workers.add_team'.tr(),
        icon: const Icon(Icons.add_circle_outline),
        iconPosition: AppButtonIconPosition.center,
        onPressed: isLoading ? null : () => context.push(WorkerRoutes.add),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppEmptyState(
        illustration: AppSvgPicture.asset(
          AppSvgs.users2,
          width: 48,
          height: 48,
          colorFilter: ColorFilter.mode(
            context.appColors.textMuted,
            BlendMode.srcIn,
          ),
        ),
        title: 'workers.empty_title'.tr(),
        description: 'workers.empty_description'.tr(),
        actionLabel: 'workers.add_team'.tr(),
        onAction: () => context.push(WorkerRoutes.add),
        actionIcon: const Icon(Icons.add, size: 20),
        actionIconPosition: AppButtonIconPosition.center,
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final retryLabel = 'empty_states.retry'.tr();
    final f = failure;

    if (f is NoInternetFailure || f is NetworkFailure) {
      return Center(
        child: AppNetworkFailureState(
          title: 'empty_states.network_title'.tr(),
          description: 'empty_states.network_description'.tr(),
          retryLabel: retryLabel,
          onRetry: onRetry,
        ),
      );
    }

    if (f is TimeoutFailure) {
      return Center(
        child: AppNetworkFailureState(
          title: 'empty_states.timeout_title'.tr(),
          description: 'empty_states.timeout_description'.tr(),
          retryLabel: retryLabel,
          onRetry: onRetry,
        ),
      );
    }

    final description = (f != null && f.message.isNotEmpty)
        ? f.message.tr()
        : 'empty_states.server_error_description'.tr();

    return Center(
      child: AppGenericEmptyState(
        title: 'empty_states.server_error_title'.tr(),
        description: description,
        actionLabel: retryLabel,
        onAction: onRetry,
      ),
    );
  }
}
