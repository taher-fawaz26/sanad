import 'dart:async';

import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:storage/storage.dart';
import 'package:workers/src/domain/entities/invitation_entity.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/widgets/invitation_list_item.dart';
import 'package:workers/src/presentation/widgets/worker_empty_states.dart';
import 'package:workers/src/presentation/widgets/worker_error_state.dart';
import 'package:workers/src/presentation/widgets/worker_search_sheet.dart';

/// Invitations tab content — mirrors `_WorkersContent` in `workers_page.dart`.
class InvitationsContent extends StatefulWidget {
  const InvitationsContent({super.key});

  @override
  State<InvitationsContent> createState() => _InvitationsContentState();
}

class _InvitationsContentState extends State<InvitationsContent> {
  /// `null` while the Hive read is in flight — the hint never arms until
  /// this resolves, so it can't briefly play before we know it's been seen.
  bool? _hintSeen;

  /// One-shot latch: once the hint has fired (played or been cancelled), row
  /// 0 renders as a plain `InvitationListItem` on every later build (filter
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
              key: StorageKeys.invitationsSwipeHintSeen,
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
        key: StorageKeys.invitationsSwipeHintSeen,
        value: true,
        boxName: HiveBoxes.defaultBox,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InvitationsListBloc, InvitationsListState>(
      builder: (context, state) {
        // First-page load: skeletonize the *real* row widget with mock data
        // (no bespoke skeleton layout) via the shared AppSkeletonizer gateway.
        if (state.status == RequestStatus.loading) {
          return AppSkeletonList(
            itemBuilder: (context, index) => InvitationListItem(
              invitation: InvitationEntity(
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
                child: AppSwipeActionsGroup(
                  child: SanadPagedList<InvitationEntity>(
                    state: toPagingState(state.pagination),
                    fetchNextPage: () =>
                        context.read<InvitationsListBloc>().add(
                          const InvitationsListLoadMoreEvent(),
                        ),
                    padding: EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      bottom: AppSpacing.lg,
                    ),
                    separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, invitation, index) =>
                        _showSwipeHintFor(index)
                        ? AppSwipeActionHint(
                            enabled: true,
                            onShown: _markHintShown,
                            builder: (context, controller) =>
                                InvitationListItem(
                                  invitation: invitation,
                                  hintController: controller,
                                ),
                          )
                        : InvitationListItem(invitation: invitation),
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
