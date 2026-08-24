import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/src/domain/entities/worker_entity.dart';
import 'package:workers/src/domain/entities/worker_status.dart';
import 'package:workers/src/presentation/widgets/worker_action_invokers.dart';

/// Per-worker "more actions" sheet for the Worker Details page — Suspend (or
/// Unsuspend)/Delete as two tappable rows, each guarded by its own
/// confirmation sheet.
///
/// Mirrors `services`' `showServiceActionsBottomSheet` shape. [context] is
/// the Worker Details page's own context (captured before the sheet is
/// pushed) — [confirmAndChangeWorkerStatus]/[confirmAndDeleteWorker] read
/// `WorkerActionCubit` from it after the sheet pops, exactly like
/// `WorkerListItem`'s swipe actions already do, so no new business logic is
/// introduced here.
Future<void> showWorkerActionsBottomSheet({
  required BuildContext context,
  required WorkerEntity worker,
}) {
  final pageContext = context;

  return SheetNavigator.push<void>(
    context,
    _WorkerActionsSheetBody(worker: worker, pageContext: pageContext),
    settings: const SheetRouteSettings(padChild: false),
  );
}

class _WorkerActionsSheetBody extends StatelessWidget {
  const _WorkerActionsSheetBody({
    required this.worker,
    required this.pageContext,
  });

  final WorkerEntity worker;
  final BuildContext pageContext;

  bool get _isSuspended => worker.status == WorkerStatus.inactive;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: AppSpacing.lg),
        _WorkerActionRow(
          label: _isSuspended
              ? 'workers.action_unsuspend'.tr()
              : 'workers.action_suspend'.tr(),
          svgAsset: AppSvgs.workerSuspend,
          color: colors.warning,
          onTap: () => _onStatusTogglePressed(context),
        ),
        const AppDivider(),
        _WorkerActionRow(
          label: 'workers.action_delete'.tr(),
          svgAsset: AppSvgs.trashBold,
          color: colors.error,
          onTap: () => _onDeletePressed(context),
        ),
      ],
    );
  }

  Future<void> _onStatusTogglePressed(BuildContext context) async {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;
    await confirmAndChangeWorkerStatus(
      context: pageContext,
      worker: worker,
      isSuspending: !_isSuspended,
    );
  }

  Future<void> _onDeletePressed(BuildContext context) async {
    Navigator.of(context).pop();
    if (!pageContext.mounted) return;
    await confirmAndDeleteWorker(context: pageContext, worker: worker);
  }
}

/// Tappable row with a colored icon + label — mirrors `services`'
/// `_ServiceActionRow` for visual parity across "more actions" sheets.
class _WorkerActionRow extends StatelessWidget {
  const _WorkerActionRow({
    required this.label,
    required this.svgAsset,
    required this.color,
    required this.onTap,
  });

  final String label;
  final String svgAsset;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          child: Row(
            children: [
              AppSvgPicture.asset(
                svgAsset,
                width: 24,
                height: 24,
                colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
              ),
              SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Text(
                  label,
                  style: typography.regularNormal.copyWith(color: color),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
