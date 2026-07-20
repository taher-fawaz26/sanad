import 'dart:async';

import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/presentation/bloc/workers/workers_bloc.dart';
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
/// Mirrors the branches search sheet: the page search field is tap-to-open
/// only; typing and results live in this modal, sharing the page's
/// [WorkersBloc]. The query is always cleared when the sheet closes.
Future<void> showWorkerSearchSheet(
  BuildContext context, {
  required WorkerSearchScope scope,
}) async {
  final bloc = context.read<WorkersBloc>();

  final result = await showAppModalSheet<_SearchSheetResult>(
    context: context,
    child: BlocProvider.value(
      value: bloc,
      child: _WorkerSearchSheetBody(scope: scope),
    ),
  );

  bloc.add(const WorkersSearchChangedEvent(''));

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
            onChanged: (value) => context.read<WorkersBloc>().add(
              WorkersSearchChangedEvent(value),
            ),
          ),
        ),
        Expanded(
          child: BlocBuilder<WorkersBloc, WorkersState>(
            builder: (context, state) {
              final hasQuery = state.searchQuery.trim().isNotEmpty;

              if (widget.scope == WorkerSearchScope.team) {
                return _TeamResults(
                  state: state,
                  hasQuery: hasQuery,
                );
              }

              return _InvitationResults(
                state: state,
                hasQuery: hasQuery,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _TeamResults extends StatelessWidget {
  const _TeamResults({required this.state, required this.hasQuery});

  final WorkersState state;
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

  final WorkersState state;
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
