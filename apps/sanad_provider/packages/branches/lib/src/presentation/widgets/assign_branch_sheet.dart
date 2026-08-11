import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/domain/usecases/branch_usecase_params.dart';
import 'package:branches/src/domain/usecases/get_branches_usecase.dart';
import 'package:branches/src/domain/usecases/update_branch_usecase.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
      _AssignBranchSheetBody(worker: worker, onWorkerUpdated: onWorkerUpdated),
      settings: const SheetRouteSettings(sheetSize: SheetSize.expanded),
    );
  }
}

class _AssignBranchSheetBody extends StatefulWidget {
  const _AssignBranchSheetBody({
    required this.worker,
    required this.onWorkerUpdated,
  });

  final WorkerEntity worker;
  final ValueChanged<WorkerEntity> onWorkerUpdated;

  @override
  State<_AssignBranchSheetBody> createState() => _AssignBranchSheetBodyState();
}

class _AssignBranchSheetBodyState extends State<_AssignBranchSheetBody> {
  List<BranchEntity>? _branches;
  BranchEntity? _selectedBranch;
  bool _loading = false;
  bool _saving = false;
  Failure? _failure;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    setState(() {
      _loading = true;
      _failure = null;
    });

    final result = await sl<GetBranchesUseCase>()
        .call(const GetBranchesParams(limit: 50))
        .run();

    if (!mounted) return;

    result.match(
      (failure) => setState(() {
        _failure = failure;
        _loading = false;
      }),
      (paginated) => setState(() {
        _branches = paginated.branches;
        _loading = false;
      }),
    );
  }

  Future<void> _onSave() async {
    if (_selectedBranch == null || _saving) return;

    final branch = _selectedBranch!;

    setState(() => _saving = true);

    final existingWorkerIds = branch.workers.map((w) => w.id).toList();
    final updatedWorkerIds = [...existingWorkerIds, widget.worker.id];

    final result = await sl<UpdateBranchUseCase>()
        .call(
          UpdateBranchParams(
            id: branch.id,
            branchName: branch.branchName,
            branchAddress: branch.branchAddress,
            branchPhone: branch.branchPhone,
            workerIds: updatedWorkerIds,
          ),
        )
        .run();

    if (!mounted) return;

    result.match(
      (failure) {
        setState(() => _saving = false);
        showAppErrorSnackbar(
          context: context,
          title: 'workers.action_failed'.tr(),
          caption: failure.localizedMessage(),
        );
      },
      (_) {
        final updatedWorker = WorkerEntity(
          id: widget.worker.id,
          fullName: widget.worker.fullName,
          role: widget.worker.role,
          initials: widget.worker.initials,
          status: widget.worker.status,
          phone: widget.worker.phone,
          email: widget.worker.email,
          jobTitle: widget.worker.jobTitle,
          profilePicUrl: widget.worker.profilePicUrl,
          assignedBranches: [
            ...widget.worker.assignedBranches,
            WorkerAssignedBranch(
              id: branch.id,
              branchName: branch.branchName,
              role: 'worker',
            ),
          ],
        );
        widget.onWorkerUpdated(updatedWorker);
        Navigator.of(context).pop();
        showAppSnackbar(
          context: context,
          title: 'workers.assign_branch_success'.tr(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(child: AppLoadingIndicator()),
      );
    }

    if (_failure != null) {
      return Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppGenericEmptyState(
              title: 'workers.action_failed'.tr(),
              description: _failure!.localizedMessage(),
            ),
            SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'workers.select_worker.retry'.tr(),
              onPressed: _loadBranches,
            ),
          ],
        ),
      );
    }

    final branches = _branches ?? [];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSelectField(
          label: 'workers.assign_branch_label'.tr(),
          value: _selectedBranch?.branchName,
          hint: 'workers.assign_branch_hint'.tr(),
          onTap: () => _openBranchPicker(branches),
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'workers.edit_worker.save_button'.tr(),
          onPressed: _selectedBranch == null || _saving ? null : _onSave,
          isLoading: _saving,
        ),
      ],
    );
  }

  Future<void> _openBranchPicker(List<BranchEntity> branches) async {
    await showAppActionSheet<void>(
      context: context,
      title: 'workers.assign_branch_label'.tr(),
      cancelLabel: 'workers.cancel'.tr(),
      items: branches
          .map(
            (branch) => AppActionSheetItem(
              label: branch.branchName,
              onTap: () => setState(() => _selectedBranch = branch),
            ),
          )
          .toList(),
    );
  }
}
