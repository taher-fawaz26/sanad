import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/domain/entities/invitation_status.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
import 'package:workers/src/presentation/widgets/invitation_actions_bottom_sheet.dart';

/// Invitations tab content — mirrors `_WorkersContent` in `workers_page.dart`.
class InvitationsContent extends StatelessWidget {
  const InvitationsContent({required this.state, super.key});

  final WorkersState state;

  @override
  Widget build(BuildContext context) {
    if (state.invitationsStatus == RequestStatus.loading) {
      return const _InvitationsLoadingSkeleton();
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
            onChanged: (value) => context.read<WorkersBloc>().add(
              WorkersSearchChangedEvent(value),
            ),
          ),
        ),
        Expanded(
          child: AppRefreshIndicator(
            onRefresh: () async {
              context.read<WorkersBloc>().add(
                const InvitationsRefreshEvent(),
              );
            },
            child:
                state.invitationsStatus == RequestStatus.failure &&
                    state.invitations.isEmpty
                ? AppFillRemainingScrollable(
                    child: _ErrorState(
                      failure: state.failure,
                      onRetry: () => context.read<WorkersBloc>().add(
                        const InvitationsRefreshEvent(),
                      ),
                    ),
                  )
                : state.filteredInvitations.isEmpty
                ? AppFillRemainingScrollable(
                    child: _EmptyState(
                      searchQuery: state.searchQuery,
                      onClearSearch: state.searchQuery.isNotEmpty
                          ? () => context.read<WorkersBloc>().add(
                              const WorkersSearchChangedEvent(''),
                            )
                          : null,
                    ),
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    itemCount: state.filteredInvitations.length,
                    itemBuilder: (context, index) => _InvitationListItem(
                      invitation: state.filteredInvitations[index],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _InvitationListItem extends StatelessWidget {
  const _InvitationListItem({required this.invitation});

  final InvitationEntity invitation;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppListCard(
        title: invitation.fullName,
        caption: invitation.role,
        leading: AppAvatar(
          initials: invitation.initials,
          backgroundColor: colors.primary,
        ),
        badge: _statusBadge(invitation.status),
        trailing: Semantics(
          label: 'workers.more_actions'.tr(),
          child: AppIconButton(
            icon: Icons.more_vert,
            iconColor: colors.textPrimary,
            onTap: () => showInvitationActionsBottomSheet(
              context: context,
              invitation: invitation,
            ),
          ),
        ),
      ),
    );
  }

  AppStatusBadge _statusBadge(InvitationStatus status) => switch (status) {
    InvitationStatus.pending => AppStatusBadge(
      label: 'workers.invitation_status_pending'.tr(),
      type: AppStatusBadgeType.warning,
      size: AppStatusBadgeSize.compact,
    ),
    InvitationStatus.accepted => AppStatusBadge(
      label: 'workers.invitation_status_accepted'.tr(),
      type: AppStatusBadgeType.success,
      size: AppStatusBadgeSize.compact,
    ),
    InvitationStatus.expired => AppStatusBadge(
      label: 'workers.invitation_status_expired'.tr(),
      type: AppStatusBadgeType.alert,
      size: AppStatusBadgeSize.compact,
    ),
  };
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery, this.onClearSearch});

  final String searchQuery;
  final VoidCallback? onClearSearch;

  @override
  Widget build(BuildContext context) {
    if (searchQuery.trim().isNotEmpty) {
      return Center(
        child: AppGenericEmptyState(
          title: 'workers.search_empty_title'.tr(),
          description: 'workers.search_empty_description'.tr(),
          actionLabel: 'workers.clear_search'.tr(),
          onAction: onClearSearch,
        ),
      );
    }
    return Center(
      child: AppGenericEmptyState(
        title: 'workers.invitations_empty_title'.tr(),
        description: 'workers.invitations_empty_description'.tr(),
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

class _InvitationsLoadingSkeleton extends StatelessWidget {
  const _InvitationsLoadingSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ShimmerListSkeleton();
  }
}
