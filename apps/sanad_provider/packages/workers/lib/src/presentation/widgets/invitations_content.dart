import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
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
                  context.read<InvitationsListBloc>().add(
                    const InvitationsListRefreshEvent(),
                  );
                },
                child: SanadPagedList<InvitationEntity>(
                  state: toPagingState(state.pagination),
                  fetchNextPage: () => context.read<InvitationsListBloc>().add(
                    const InvitationsListLoadMoreEvent(),
                  ),
                  padding: EdgeInsets.only(
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                    bottom: AppSpacing.lg,
                  ),
                  separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, invitation, index) =>
                      InvitationListItem(invitation: invitation),
                  firstPageErrorIndicatorBuilder: (_) => Center(
                    child: WorkerErrorState(
                      failure: state.failure,
                      onRetry: () => context.read<InvitationsListBloc>().add(
                        const InvitationsListRefreshEvent(),
                      ),
                    ),
                  ),
                  newPageErrorIndicatorBuilder: (_) => _NextPageErrorRetry(
                    onRetry: () => context.read<InvitationsListBloc>().add(
                      const InvitationsListLoadMoreEvent(),
                    ),
                  ),
                  noItemsFoundIndicatorBuilder: (_) =>
                      const Center(child: _EmptyState()),
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

/// Compact "load more failed" footer — mirrors the one in `workers_page.dart`
/// (kept local since each list owns its own retry event type).
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
