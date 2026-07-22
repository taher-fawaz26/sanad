import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
import 'package:workers/src/presentation/widgets/invitations_content.dart';
import 'package:workers/src/presentation/widgets/worker_empty_states.dart';
import 'package:workers/src/presentation/widgets/worker_error_state.dart';
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
            final failure = state.actionFailure!;
            final title = failure.message.trim().isEmpty
                ? 'workers.action_failed'.tr()
                : failure.localizedMessage();
            showAppErrorSnackbar(context: context, title: title);
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
                    child: WorkerErrorState(
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

/// Opens the add-worker flow and refreshes the list if a worker was added.
/// The add page pops `true` on success — see EH-S3-02 refresh convention.
Future<void> _openAddWorker(BuildContext context) async {
  final added = await context.push<bool>(WorkerRoutes.add);
  if ((added ?? false) && context.mounted) {
    context.read<WorkersBloc>().add(const WorkersRefreshEvent());
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
        onPressed: isLoading ? null : () => _openAddWorker(context),
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
        onAction: () => _openAddWorker(context),
        actionIcon: const Icon(Icons.add, size: 20),
        actionIconPosition: AppButtonIconPosition.center,
      ),
    );
  }
}
