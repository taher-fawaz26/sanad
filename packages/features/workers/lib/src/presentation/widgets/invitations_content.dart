import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/widgets/invitation_list_item.dart';
import 'package:workers/src/presentation/widgets/worker_empty_states.dart';
import 'package:workers/src/presentation/widgets/worker_error_state.dart';
import 'package:workers/src/presentation/widgets/worker_search_sheet.dart';

/// Invitations tab content — mirrors `_WorkersContent` in `workers_page.dart`.
class InvitationsContent extends StatelessWidget {
  const InvitationsContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvitationsListBloc, InvitationsListState>(
      builder: (context, state) {
        if (state.status == RequestStatus.loading) {
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
                hint: 'workers.invitations_search_hint'.tr(),
                showMicIcon: false,
                readOnly: true,
                onTap: () => showWorkerSearchSheet(
                  context,
                  scope: WorkerSearchScope.invitations,
                ),
              ),
            ),
            Expanded(
              child: AppRefreshIndicator(
                onRefresh: () async {
                  context
                      .read<InvitationsListBloc>()
                      .add(const InvitationsListRefreshEvent());
                },
                child: state.status == RequestStatus.failure &&
                        state.invitations.isEmpty
                    ? AppFillRemainingScrollable(
                        child: WorkerErrorState(
                          failure: state.failure,
                          onRetry: () => context
                              .read<InvitationsListBloc>()
                              .add(const InvitationsListRefreshEvent()),
                        ),
                      )
                    : state.filteredInvitations.isEmpty
                    ? const AppFillRemainingScrollable(child: _EmptyState())
                    : NotificationListener<ScrollNotification>(
                        onNotification: (notification) {
                          if (notification.metrics.pixels >=
                                  notification.metrics.maxScrollExtent - 200 &&
                              state.hasMore &&
                              !state.loadingMore) {
                            context
                                .read<InvitationsListBloc>()
                                .add(const InvitationsListLoadMoreEvent());
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
                          itemCount: state.filteredInvitations.length +
                              (state.loadingMore ? 1 : 0),
                          separatorBuilder: (_, _) =>
                              SizedBox(height: AppSpacing.sm),
                          itemBuilder: (context, index) {
                            if (index >= state.filteredInvitations.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: AppLoadingIndicator()),
                              );
                            }
                            return InvitationListItem(
                              invitation: state.filteredInvitations[index],
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
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppGenericEmptyState(
        title: 'workers.invitations_empty_title'.tr(),
        description: 'workers.invitations_empty_description'.tr(),
      ),
    );
  }
}
