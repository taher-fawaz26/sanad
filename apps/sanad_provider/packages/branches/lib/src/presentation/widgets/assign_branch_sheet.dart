import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/assign_branch/assign_branch_bloc.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/workers.dart';

class BranchesWorkerBranchAssigner implements WorkerBranchAssigner {
  const BranchesWorkerBranchAssigner();

  @override
  Future<void> showAssignBranchSheet({
    required BuildContext context,
    required WorkerEntity worker,
    required ValueChanged<WorkerEntity> onWorkerUpdated,
  }) {
    return SheetNavigator.push<void>(
      context,
      BlocProvider<AssignBranchBloc>(
        create: (_) =>
            sl<AssignBranchBloc>(param1: worker)
              ..add(const AssignBranchLoadEvent()),
        child: _AssignBranchSheetBody(onWorkerUpdated: onWorkerUpdated),
      ),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
  }
}

class _AssignBranchSheetBody extends StatelessWidget {
  const _AssignBranchSheetBody({required this.onWorkerUpdated});

  final ValueChanged<WorkerEntity> onWorkerUpdated;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AssignBranchBloc, AssignBranchState>(
          listenWhen: (previous, current) =>
              previous.saveStatus != current.saveStatus &&
              current.saveStatus == RequestStatus.success &&
              current.updatedWorker != null,
          listener: (context, state) {
            onWorkerUpdated(state.updatedWorker!);
            Navigator.of(context).pop();
            showAppSnackbar(
              context: context,
              title: 'workers.assign_branch_success'.tr(),
            );
          },
        ),
        BlocListener<AssignBranchBloc, AssignBranchState>(
          listenWhen: (previous, current) =>
              previous.saveStatus != current.saveStatus &&
              current.saveStatus == RequestStatus.failure &&
              current.saveFailure != null,
          listener: (context, state) {
            showAppErrorSnackbar(
              context: context,
              title: 'workers.action_failed'.tr(),
              caption: state.saveFailure!.localizedMessage(),
            );
          },
        ),
      ],
      child: BlocBuilder<AssignBranchBloc, AssignBranchState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: AppLoadingIndicator()),
            );
          }

          if (state.loadFailure != null) {
            return Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppGenericEmptyState(
                    title: 'workers.action_failed'.tr(),
                    description: state.loadFailure!.localizedMessage(),
                  ),
                  SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'common.retry'.tr(),
                    onPressed: () => context.read<AssignBranchBloc>().add(
                      const AssignBranchLoadEvent(),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSelectField(
                label: 'workers.assign_branch_label'.tr(),
                value: state.selectedBranch?.branchName,
                hint: 'workers.assign_branch_hint'.tr(),
                onTap: () => _openBranchPicker(context, state.branches),
              ),
              SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'common.save'.tr(),
                onPressed: state.canSubmit
                    ? () => context.read<AssignBranchBloc>().add(
                        const AssignBranchSubmitEvent(),
                      )
                    : null,
                isLoading: state.isSaving,
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openBranchPicker(
    BuildContext context,
    List<BranchEntity> branches,
  ) async {
    final bloc = context.read<AssignBranchBloc>();
    await SheetNavigator.push<void>(
      context,
      AppActionList(
        items: branches
            .map(
              (branch) => AppActionSheetItem(
                label: branch.branchName,
                onTap: () => bloc.add(AssignBranchSelectedEvent(branch)),
              ),
            )
            .toList(),
      ),
      settings: SheetRouteSettings(
        title: 'workers.assign_branch_label'.tr(),
        padChild: false,
      ),
    );
  }
}
