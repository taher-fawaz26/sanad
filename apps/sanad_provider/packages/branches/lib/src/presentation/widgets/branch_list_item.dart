import 'package:app_assets/app_assets.dart';
import 'package:authorization/authorization.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/utils/branch_type_formatter.dart';
import 'package:branches/src/presentation/widgets/branch_action_invokers.dart';
import 'package:branches/src/routes/branch_permissions.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

/// Swipe-group tag shared by every [BranchListItem] so only one row's swipe
/// actions stay open at a time — wrap the list in `AppSwipeActionsGroup`.
const branchSwipeGroupTag = 'branches';

/// A single branch row — Figma branch card (`347:14361`).
///
/// Shared by the main branches list and the search bottom sheet so both
/// stay visually identical. Contextual actions (Edit / Maintenance / Delete)
/// are exposed only via swipe-to-reveal (`AppSwipeActions`), matching the
/// Teams/Services/Invitations rows.
class BranchListItem extends StatelessWidget {
  const BranchListItem({required this.branch, super.key, this.onTap});

  final BranchEntity branch;

  /// Overrides the default "open branch details" navigation — used by the
  /// search sheet to close itself before navigating.
  final VoidCallback? onTap;

  static Color _avatarColor(AppColors colors, String seed) {
    final palette = <Color>[
      colors.palettes.sky.shade400,
      colors.palettes.accent.shade400,
      colors.palettes.main.shade600,
    ];
    return palette[seed.hashCode.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final initial = branch.branchName.isNotEmpty
        ? branch.branchName[0].toUpperCase()
        : '?';

    return ListenableBuilder(
      listenable: sl<AuthorizationReader>(),
      builder: (context, _) => _buildSwipeRow(context, colors, initial),
    );
  }

  Widget _buildSwipeRow(
    BuildContext context,
    AppColors colors,
    String initial,
  ) {
    final reader = sl<AuthorizationReader>();
    // Edit only navigates to the (read-only-safe) details page, so it is
    // gated on view — not update. See the migration plan's "the read-only
    // page distinction" for why.
    final canEdit = reader.can(BranchPermissions.view);
    final canToggleMaintenance = reader.can(BranchPermissions.update);

    return AppSwipeActions(
      groupTag: branchSwipeGroupTag,
      actions: [
        if (canEdit)
          AppSwipeAction(
            svgAsset: AppSvgs.branchEdit,
            semanticLabel: 'branches.actions.action_edit'.tr(),
            onPressed: () => editBranch(context: context, branch: branch),
          ),
        if (canToggleMaintenance)
          AppSwipeAction(
            svgAsset: AppSvgs.branchMaintenance,
            semanticLabel: branch.isAvailable
                ? 'branches.actions.action_set_maintenance'.tr()
                : 'branches.actions.action_set_active'.tr(),
            variant: branch.isAvailable
                ? AppSwipeActionVariant.warning
                : AppSwipeActionVariant.primary,
            onPressed: () => confirmAndToggleBranchMaintenance(
              context: context,
              branch: branch,
            ),
          ),
        // Delete has no backend permission yet (gap tracked in the RBAC
        // migration plan) — stays unconditional; the route itself is still
        // organization-only via the persona guard.
        AppSwipeAction(
          svgAsset: AppSvgs.trashBold,
          semanticLabel: 'branches.actions.action_delete'.tr(),
          variant: AppSwipeActionVariant.destructive,
          onPressed: () =>
              confirmAndDeleteBranch(context: context, branch: branch),
        ),
      ],
      child: AppEntityListItem(
        style: AppEntityListItemStyle.compact,
        title: branch.branchName,
        caption: BranchTypeFormatter.localizedLabel(branch.branchType),
        leading: AppAvatar(
          initials: initial,
          backgroundColor: _avatarColor(colors, branch.id),
          showStatusDot: true,
        ),
        badge: AppStatusBadge(
          label: branch.isAvailable
              ? 'branches.status_active'.tr()
              : 'branches.status_maintenance'.tr(),
          type: branch.isAvailable
              ? AppStatusBadgeType.success
              : AppStatusBadgeType.warning,
          size: AppStatusBadgeSize.compact,
        ),
        onTap: onTap ?? () => context.push(BranchRoutes.detailsFor(branch.id)),
      ),
    );
  }
}
