import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/usecases/get_workers_usecase.dart';

/// Result returned when the user confirms worker selection.
class SelectWorkerResult {
  const SelectWorkerResult({required this.selectedWorkers});

  final List<WorkerEntity> selectedWorkers;
}

/// Figma `add worker` action sheet (`251:7333`).
///
/// Loads workers from [GetWorkersUseCase], supports multi-select with search,
/// and returns the confirmed selection.
Future<SelectWorkerResult?> showSelectWorkerActionSheet({
  required BuildContext context,
  Set<String> initialSelectedIds = const {},
}) async {
  final selected = await showAppSelectSheet<WorkerEntity>(
    context: context,
    title: 'workers.select_worker.title'.tr(),
    confirmLabel: 'workers.select_worker.confirm'.tr(),
    searchHint: 'workers.select_worker.search_hint'.tr(),
    getId: (w) => w.id,
    searchFilter: (w, q) =>
        w.fullName.toLowerCase().contains(q) ||
        w.role.toLowerCase().contains(q),
    initialSelectedIds: initialSelectedIds,
    loadItems: () async {
      final result = await sl<GetWorkersUseCase>()(
        const WorkersQuery(limit: 100),
      ).run();
      return result.fold((f) => throw f, (paged) => paged.items);
    },
    errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
    retryLabel: 'workers.select_worker.retry'.tr(),
    emptyBuilder: (context) => _WorkerEmptyState(),
    itemBuilder: (context, worker, isSelected, onTap) => AppTableRow(
      title: worker.fullName,
      caption: worker.role,
      leading: AppTableLeading.avatar,
      leadingAvatar: AppAvatar(
        initials: worker.initials,
        backgroundColor: context.appColors.primary,
        showStatusDot: true,
      ),
      trailing: AppTableTrailing.icon,
      trailingIcon: AppCheckbox(
        value: isSelected,
        onChanged: (_) => onTap(),
      ),
      onTap: onTap,
    ),
  );
  if (selected == null) return null;
  return SelectWorkerResult(selectedWorkers: selected);
}

class _WorkerEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;
    final colors = context.appColors;
    final iconSize = responsiveDimension(48);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgPicture.asset(
              AppSvgs.users2,
              width: iconSize,
              height: iconSize,
            ),
            SizedBox(height: AppSpacing.lg),
            Text(
              'workers.select_worker.empty'.tr(),
              textAlign: TextAlign.center,
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(color: colors.textPrimary),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              'workers.select_worker.empty_description'.tr(),
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
