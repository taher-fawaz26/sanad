import 'package:app_assets/app_assets.dart';
import 'package:branches/src/presentation/widgets/branch_pin_empty_body.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/workers.dart';

/// Add branch — Step 4 workers.
///
/// Empty: Figma `245:6400` (body `1563:11012`).
/// Filled: Figma `956:3701`.
class AddBranchWorkersStep extends StatelessWidget {
  const AddBranchWorkersStep({
    required this.selectedWorkers,
    required this.onAddWorkers,
    required this.onRemoveWorker,
    super.key,
  });

  final List<WorkerEntity> selectedWorkers;
  final VoidCallback onAddWorkers;
  final ValueChanged<WorkerEntity> onRemoveWorker;

  bool get _hasWorkers => selectedWorkers.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (_hasWorkers) {
      return _WorkersSetContent(
        selectedWorkers: selectedWorkers,
        onAddWorkers: onAddWorkers,
        onRemoveWorker: onRemoveWorker,
      );
    }

    final iconSize = responsiveDimension(48);
    return GestureDetector(
      onTap: onAddWorkers,
      behavior: HitTestBehavior.opaque,
      child: BranchPinEmptyBody(
        icon: AppSvgPicture.asset(
          AppSvgs.users2,
          width: iconSize,
          height: iconSize,
        ),
        title: 'branches.add_branch.workers_title'.tr(),
        description: 'branches.add_branch.workers_description'.tr(),
      ),
    );
  }
}

/// Figma filled workers step (`956:3701`).
class _WorkersSetContent extends StatelessWidget {
  const _WorkersSetContent({
    required this.selectedWorkers,
    required this.onAddWorkers,
    required this.onRemoveWorker,
  });

  final List<WorkerEntity> selectedWorkers;
  final VoidCallback onAddWorkers;
  final ValueChanged<WorkerEntity> onRemoveWorker;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final worker in selectedWorkers) ...[
            WorkerListCard(
              worker: worker,
              onRemove: () => onRemoveWorker(worker),
            ),
            SizedBox(height: AppSpacing.md),
          ],
          SizedBox(height: AppSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButtonPresets.outline(
              label: 'branches.add_branch.add_more_workers_button'.tr(),
              size: AppButtonSize.large,
              icon: const Icon(Icons.add_circle_outline),
              iconPosition: AppButtonIconPosition.left,
              onPressed: onAddWorkers,
            ),
          ),
        ],
      ),
    );
  }
}
