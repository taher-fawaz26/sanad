import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/presentation/bloc/invitations_list/invitations_list_bloc.dart';
import 'package:workers/src/presentation/bloc/workers_list/workers_list_bloc.dart';
import 'package:workers/src/presentation/widgets/invitation_list_item.dart';
import 'package:workers/src/presentation/widgets/worker_empty_states.dart';
import 'package:workers/src/presentation/widgets/worker_list_item.dart';
import 'package:workers/src/routes/worker_routes.dart';

/// What the user did inside the search sheet.
sealed class _SearchSheetResult {
  const _SearchSheetResult();
}

class _ViewWorker extends _SearchSheetResult {
  const _ViewWorker(this.worker);
  final WorkerEntity worker;
}

class _StartAddWorker extends _SearchSheetResult {
  const _StartAddWorker();
}

/// Workers / invitations search — bottom sheet (Figma `1526:12837`).
///
/// The page search field is tap-to-open only; typing and results live in this
/// modal, which reuses the page's list blocs. The query is always cleared
/// when the sheet closes so the underlying list resets.
Future<void> showWorkerSearchSheet(
  BuildContext context, {
  required WorkerSearchScope scope,
}) async {
  // Grab both blocs — the sheet reads from whichever matches [scope] but the
  // reset on close always runs against the right one.
  final workersList = context.read<WorkersListBloc>();
  final invitationsList = context.read<InvitationsListBloc>();

  final result = await SheetNavigator.push<_SearchSheetResult>(
    context,
    MultiBlocProvider(
      providers: [
        BlocProvider.value(value: workersList),
        BlocProvider.value(value: invitationsList),
      ],
      child: _WorkerSearchSheetBody(scope: scope),
    ),
    settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
  );

  // Only reset when the user actually typed something — clearing an already
  // empty query would still trigger the debounced refetch.
  switch (scope) {
    case WorkerSearchScope.team:
      if (workersList.state.searchQuery.isNotEmpty) {
        workersList.add(const WorkersListSearchChangedEvent(''));
      }
    case WorkerSearchScope.invitations:
      if (invitationsList.state.searchQuery.isNotEmpty) {
        invitationsList.add(const InvitationsListSearchChangedEvent(''));
      }
  }

  if (!context.mounted) return;
  switch (result) {
    case _ViewWorker(:final worker):
      unawaited(
        context.push(
          WorkerRoutes.detailsFor(worker.id),
          extra: worker,
        ),
      );
    case _StartAddWorker():
      unawaited(context.push(WorkerRoutes.add));
    case null:
      break;
  }
}

class _WorkerSearchSheetBody extends StatefulWidget {
  const _WorkerSearchSheetBody({required this.scope});

  final WorkerSearchScope scope;

  @override
  State<_WorkerSearchSheetBody> createState() => _WorkerSearchSheetBodyState();
}

class _WorkerSearchSheetBodyState extends State<_WorkerSearchSheetBody> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hint = switch (widget.scope) {
      WorkerSearchScope.team => 'workers.search_hint'.tr(),
      WorkerSearchScope.invitations => 'workers.invitations_search_hint'.tr(),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: AppSearchField(
            controller: _controller,
            variant: AppSearchFieldVariant.bordered,
            hint: hint,
            showMicIcon: false,
            autofocus: true,
            onChanged: (value) => switch (widget.scope) {
              WorkerSearchScope.team => context.read<WorkersListBloc>().add(
                WorkersListSearchChangedEvent(value),
              ),
              WorkerSearchScope.invitations =>
                context.read<InvitationsListBloc>().add(
                  InvitationsListSearchChangedEvent(value),
                ),
            },
          ),
        ),
        Expanded(
          child: widget.scope == WorkerSearchScope.team
              ? BlocBuilder<WorkersListBloc, WorkersListState>(
                  builder: (context, state) => _TeamResults(
                    state: state,
                    hasQuery: state.searchQuery.trim().isNotEmpty,
                  ),
                )
              : BlocBuilder<InvitationsListBloc, InvitationsListState>(
                  builder: (context, state) => _InvitationResults(
                    state: state,
                    hasQuery: state.searchQuery.trim().isNotEmpty,
                  ),
                ),
        ),
      ],
    );
  }
}

class _TeamResults extends StatelessWidget {
  const _TeamResults({required this.state, required this.hasQuery});

  final WorkersListState state;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final workers = state.filteredWorkers;

    if (workers.isEmpty) {
      return Center(
        child: hasQuery
            ? WorkersSearchEmptyState(
                scope: WorkerSearchScope.team,
                onCancel: () => Navigator.of(context).pop(),
              )
            : AppEmptyState(
                illustration: AppSvgPicture.asset(
                  AppSvgs.users2,
                  width: responsiveDimension(48),
                  height: responsiveDimension(48),
                  colorFilter: ColorFilter.mode(
                    context.appColors.textMuted,
                    BlendMode.srcIn,
                  ),
                ),
                title: 'workers.empty_title'.tr(),
                description: 'workers.empty_description'.tr(),
                actionLabel: 'workers.add_team'.tr(),
                onAction: () => Navigator.of(
                  context,
                ).pop(const _StartAddWorker()),
                actionIcon: const Icon(Icons.add, size: 20),
                actionIconPosition: AppButtonIconPosition.center,
              ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      itemCount: workers.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final worker = workers[index];
        return WorkerListItem(
          worker: worker,
          onTap: () => Navigator.of(context).pop(_ViewWorker(worker)),
        );
      },
    );
  }
}

class _InvitationResults extends StatelessWidget {
  const _InvitationResults({required this.state, required this.hasQuery});

  final InvitationsListState state;
  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    final invitations = state.filteredInvitations;

    if (invitations.isEmpty) {
      return Center(
        child: hasQuery
            ? WorkersSearchEmptyState(
                scope: WorkerSearchScope.invitations,
                onCancel: () => Navigator.of(context).pop(),
              )
            : AppGenericEmptyState(
                title: 'workers.invitations_empty_title'.tr(),
                description: 'workers.invitations_empty_description'.tr(),
              ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      itemCount: invitations.length,
      separatorBuilder: (_, _) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) => InvitationListItem(
        invitation: invitations[index],
      ),
    );
  }
}
