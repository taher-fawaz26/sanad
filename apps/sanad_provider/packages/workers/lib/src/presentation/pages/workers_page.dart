import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/presentation/bloc/invitation_action/invitation_action_cubit.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/bloc/worker_action/worker_action_cubit.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
import 'package:workers/src/presentation/services/worker_roles_tab.dart';
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
  int _selectedTab = 0;

  StreamSubscription<WorkerActionEffect>? _workerEffectsSub;
  StreamSubscription<InvitationActionEffect>? _invitationEffectsSub;

  @override
  void initState() {
    super.initState();
    context.read<WorkersListBloc>().add(const WorkersListFetchEvent());
    _workerEffectsSub = context.read<WorkerActionCubit>().effects.listen(
      _onWorkerEffect,
    );
    _invitationEffectsSub = context
        .read<InvitationActionCubit>()
        .effects
        .listen(_onInvitationEffect);
  }

  @override
  void dispose() {
    _workerEffectsSub?.cancel();
    _invitationEffectsSub?.cancel();
    super.dispose();
  }

  // ── Effect handling ──────────────────────────────────────────────────────

  void _onWorkerEffect(WorkerActionEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case WorkerActionStarted(:final type):
        AppProgress.show(context, title: _workerProgressTitle(type));
      case WorkerActionSucceeded(
        :final type,
        :final workerId,
        :final updatedWorker,
      ):
        AppProgress.dismiss();
        if (type == WorkerActionType.delete) {
          context.read<WorkersListBloc>().add(
            WorkerRemovedFromListEvent(workerId),
          );
        } else if (updatedWorker != null) {
          context.read<WorkersListBloc>().add(
            WorkerReplacedInListEvent(updatedWorker),
          );
        }
        showAppSnackbar(context: context, title: _workerSuccessMessage(type));
      case WorkerActionFailed(:final type, :final failure):
        AppProgress.dismiss();
        showAppErrorSnackbar(
          context: context,
          title: _workerFailureMessage(type, failure),
        );
    }
  }

  void _onInvitationEffect(InvitationActionEffect effect) {
    if (!mounted) return;
    switch (effect) {
      case InvitationActionStarted(:final type):
        AppProgress.show(context, title: _invitationProgressTitle(type));
      case InvitationActionSucceeded(:final type, :final invitationId):
        AppProgress.dismiss();
        final invitations = context.read<InvitationsListBloc>();
        switch (type) {
          case InvitationActionType.cancel:
            invitations.add(InvitationCancelledInListEvent(invitationId));
          case InvitationActionType.delete:
            invitations.add(InvitationRemovedFromListEvent(invitationId));
          case InvitationActionType.resend:
            break;
        }
        showAppSnackbar(
          context: context,
          title: _invitationSuccessMessage(type),
        );
      case InvitationActionFailed(:final type, :final failure):
        AppProgress.dismiss();
        showAppErrorSnackbar(
          context: context,
          title: _invitationFailureMessage(type, failure),
        );
    }
  }

  // ── Copy helpers ─────────────────────────────────────────────────────────

  String _workerProgressTitle(WorkerActionType type) => switch (type) {
    WorkerActionType.suspend => 'workers.worker_suspend_in_progress'.tr(),
    WorkerActionType.unsuspend => 'workers.worker_unsuspend_in_progress'.tr(),
    WorkerActionType.delete => 'workers.worker_delete_in_progress'.tr(),
  };

  String _workerSuccessMessage(WorkerActionType type) => switch (type) {
    WorkerActionType.suspend => 'workers.worker_suspended'.tr(),
    WorkerActionType.unsuspend => 'workers.worker_unsuspended'.tr(),
    WorkerActionType.delete => 'workers.worker_deleted'.tr(),
  };

  String _workerFailureMessage(WorkerActionType type, Failure failure) {
    if (failure.message.trim().isNotEmpty) return failure.localizedMessage();
    return switch (type) {
      WorkerActionType.suspend => 'workers.worker_suspend_failed'.tr(),
      WorkerActionType.unsuspend => 'workers.worker_unsuspend_failed'.tr(),
      WorkerActionType.delete => 'workers.worker_delete_failed'.tr(),
    };
  }

  String _invitationProgressTitle(InvitationActionType type) => switch (type) {
    InvitationActionType.resend => 'workers.invitation_resend_in_progress'.tr(),
    InvitationActionType.cancel => 'workers.invitation_cancel_in_progress'.tr(),
    InvitationActionType.delete => 'workers.invitation_delete_in_progress'.tr(),
  };

  String _invitationSuccessMessage(InvitationActionType type) => switch (type) {
    InvitationActionType.resend => 'workers.invitation_resent'.tr(),
    InvitationActionType.cancel => 'workers.invitation_cancelled'.tr(),
    InvitationActionType.delete => 'workers.invitation_deleted'.tr(),
  };

  String _invitationFailureMessage(
    InvitationActionType type,
    Failure failure,
  ) {
    // Backend email service rejects reserved demo domains — surface a clearer
    // message than the raw "Failed to send email:..." string.
    final raw = failure.message.trim();
    if (type == InvitationActionType.resend &&
        raw.toLowerCase().contains('failed to send email')) {
      return 'workers.invitation_resend_email_domain_error'.tr();
    }

    if (raw.isNotEmpty) return failure.localizedMessage();
    return switch (type) {
      InvitationActionType.resend => 'workers.invitation_resend_failed'.tr(),
      InvitationActionType.cancel => 'workers.invitation_cancel_failed'.tr(),
      InvitationActionType.delete => 'workers.invitation_delete_failed'.tr(),
    };
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appColors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: 'workers.title'.tr(),
              showBackButton: true,
              onLeadingTap: () => context.pop(),
              trailing: AppNotificationIcon(onTap: () {}),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: AppSegmentedControl<int>(
                items: [
                  AppSegmentedControlItem(
                    value: 0,
                    label: 'workers.tab_team'.tr(),
                  ),
                  AppSegmentedControlItem(
                    value: 1,
                    label: 'workers.tab_invitations'.tr(),
                  ),
                  AppSegmentedControlItem(
                    value: 2,
                    label: 'workers.tab_roles'.tr(),
                  ),
                ],
                selectedValue: _selectedTab,
                onChanged: _onTabChanged,
              ),
            ),
            Expanded(child: _buildTabBody()),
            // The Roles pane owns its own floating "add" action, so the
            // shared "Add team" footer is hidden there.
            if (_selectedTab != 2)
              _FooterButton(onAdd: () => _openAddWorker(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBody() {
    switch (_selectedTab) {
      case 0:
        return const _WorkersContent();
      case 1:
        return const InvitationsContent();
      case 2:
        // Roles pane is contributed by `provider_rbac` through the
        // `WorkerRolesTabView` port (DI), keeping `workers` free of a
        // dependency back on `provider_rbac`.
        return sl.isRegistered<WorkerRolesTabView>()
            ? sl<WorkerRolesTabView>().build()
            : const SizedBox.shrink();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabChanged(int index) {
    setState(() => _selectedTab = index);
    if (index == 1 &&
        context.read<InvitationsListBloc>().state.status ==
            RequestStatus.initial) {
      context.read<InvitationsListBloc>().add(
        const InvitationsListFetchEvent(),
      );
    }
  }
}

class _WorkersContent extends StatelessWidget {
  const _WorkersContent();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkersListBloc, WorkersListState>(
      builder: (context, state) {
        // First-page load: skeletonize the *real* row widget with mock data
        // (no bespoke skeleton layout) via the shared AppSkeletonizer gateway.
        if (state.isLoading) {
          return AppSkeletonList(
            itemBuilder: (context, index) => WorkerListItem(
              worker: WorkerEntity(
                id: 'skeleton-$index',
                fullName: BoneMock.fullName,
                role: BoneMock.name,
                initials: 'SN',
              ),
            ),
          );
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
                  context.read<WorkersListBloc>().add(
                    const WorkersListRefreshEvent(),
                  );
                },
                child: AppSwipeActionsGroup(
                  child: SanadPagedList<WorkerEntity>(
                    state: toPagingState(state.pagination),
                    fetchNextPage: () => context.read<WorkersListBloc>().add(
                      const WorkersListLoadMoreEvent(),
                    ),
                    padding: EdgeInsetsDirectional.only(
                      start: AppSpacing.lg,
                      end: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, worker, index) =>
                        RepaintBoundary(child: WorkerListItem(worker: worker)),
                    firstPageErrorIndicatorBuilder: (_) => Center(
                      child: WorkerErrorState(
                        failure: state.failure,
                        onRetry: () => context.read<WorkersListBloc>().add(
                          const WorkersListRefreshEvent(),
                        ),
                      ),
                    ),
                    newPageErrorIndicatorBuilder: (_) => _NextPageErrorRetry(
                      onRetry: () => context.read<WorkersListBloc>().add(
                        const WorkersListLoadMoreEvent(),
                      ),
                    ),
                    noItemsFoundIndicatorBuilder: (_) =>
                        Center(child: _EmptyState()),
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

/// Opens the add-worker flow and refreshes the list if a worker was added.
/// The add page pops `true` on success — see EH-S3-02 refresh convention.
Future<void> _openAddWorker(BuildContext context) async {
  final added = await context.push<bool>(WorkerRoutes.add);
  if ((added ?? false) && context.mounted) {
    context.read<WorkersListBloc>().add(const WorkersListRefreshEvent());
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return BlocSelector<WorkersListBloc, WorkersListState, bool>(
      selector: (s) => s.isLoading,
      builder: (context, isLoading) => Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.md,
        ),
        child: AppButton(
          label: 'workers.add_team'.tr(),
          icon: const Icon(Icons.add_circle_outline),
          iconPosition: AppButtonIconPosition.center,
          onPressed: isLoading ? null : onAdd,
        ),
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

/// Compact "load more failed" footer shown by [SanadPagedList] in place of the
/// next-page loading indicator — keeps already-loaded rows visible instead of
/// replacing the whole list, unlike [WorkerErrorState].
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
