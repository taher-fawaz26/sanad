import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/bloc/branches/branches_bloc.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Navigates directly to [branch]'s Details/Review screen (editing is not
/// destructive, so no confirmation gate) — the canonical Branch edit surface,
/// where every section has its own pencil-edit bottom sheet.
///
/// There is no dedicated edit wizard/screen for an existing branch: the same
/// destination the row itself opens on tap is also where "Edit" leads.
Future<void> editBranch({
  required BuildContext context,
  required BranchEntity branch,
}) {
  return context.push(BranchRoutes.detailsFor(branch.id));
}

/// Confirms then toggles [branch] between active and under-maintenance via
/// [BranchesBloc].
Future<void> confirmAndToggleBranchMaintenance({
  required BuildContext context,
  required BranchEntity branch,
}) async {
  final goingUnderMaintenance = branch.isAvailable;
  final confirmed = await showConfirmationSheet(
    context: context,
    title: goingUnderMaintenance
        ? 'branches.actions.maintenance_confirm_title'.tr()
        : 'branches.actions.activate_confirm_title'.tr(),
    description: goingUnderMaintenance
        ? 'branches.actions.maintenance_confirm_description'.tr(
            namedArgs: {'name': branch.branchName},
          )
        : 'branches.actions.activate_confirm_description'.tr(
            namedArgs: {'name': branch.branchName},
          ),
    actionLabel: 'common.confirm'.tr(),
    cancelLabel: 'common.cancel'.tr(),
    actionIntent: goingUnderMaintenance
        ? AppButtonIntent.warning
        : AppButtonIntent.standard,
  );

  if ((confirmed ?? false) && context.mounted) {
    context.read<BranchesBloc>().add(
      BranchStatusChangedEvent(
        branchId: branch.id,
        isAvailable: !branch.isAvailable,
      ),
    );
  }
}

/// Confirms then deletes [branch] via [BranchesBloc].
Future<void> confirmAndDeleteBranch({
  required BuildContext context,
  required BranchEntity branch,
}) async {
  final confirmed = await showConfirmationSheet(
    context: context,
    title: 'branches.actions.delete_confirm_title'.tr(),
    description: 'branches.actions.delete_confirm_description'.tr(),
    badgeLabel: branch.branchName,
    actionLabel: 'common.delete'.tr(),
    cancelLabel: 'common.cancel'.tr(),
    actionIntent: AppButtonIntent.destructive,
  );

  if ((confirmed ?? false) && context.mounted) {
    context.read<BranchesBloc>().add(BranchDeletedEvent(branch.id));
  }
}
