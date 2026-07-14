import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:workers/workers.dart';

/// Add branch — Step 4 workers.
///
/// Empty: Figma `245:6400`.
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

    return Center(
      child: AppEmptyState(
        illustration: AppEmptyStateImage(
          assetPath: AppImages.addWorkers,
          width: responsiveDimension(155),
          height: responsiveDimension(188),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSection(
            title: 'branches.add_branch.added_workers_section'.tr(
              namedArgs: {'count': '${selectedWorkers.length}'},
            ),
            size: AppSectionSize.compact,
            tone: AppSectionTone.primary,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Column(
              children: [
                for (var i = 0; i < selectedWorkers.length; i++) ...[
                  if (i > 0) SizedBox(height: AppSpacing.sm),
                  WorkerListCard(
                    worker: selectedWorkers[i],
                    onRemove: () => onRemoveWorker(selectedWorkers[i]),
                  ),
                ],
                SizedBox(height: AppSpacing.md),
                AppButtonPresets.outline(
                  label: 'branches.add_branch.add_more_workers_button'.tr(),
                  icon: const Icon(Icons.add, size: 20),
                  iconPosition: AppButtonIconPosition.left,
                  onPressed: onAddWorkers,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
