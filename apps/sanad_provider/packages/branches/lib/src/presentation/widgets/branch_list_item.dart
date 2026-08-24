import 'package:app_assets/app_assets.dart';
import 'package:authorization/authorization.dart';
import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/utils/branch_type_formatter.dart';
import 'package:branches/src/presentation/widgets/branch_action_invokers.dart';
import 'package:branches/src/routes/branch_permissions.dart';
import 'package:branches/src/routes/branch_routes.dart';
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
  const BranchListItem({
    required this.branch,
    super.key,
    this.onTap,
    this.isOwner = false,
    this.hintController,
  });

  final BranchEntity branch;

  /// Overrides the default "open branch details" navigation — used by the
  /// search sheet to close itself before navigating.
  final VoidCallback? onTap;

  /// Whether the signed-in account is a provider owner (individual or
  /// organization) — gates the Delete swipe.
  ///
  /// Delete is **persona-controlled, not permission-controlled**: the
  /// backend defines no `provider:branch:delete` permission (gap G2 in
  /// the RBAC backend-gaps ticket), so there is nothing to evaluate via
  /// `PermissionBuilder`/`PermissionGate`. Deliberately NOT proxied on
  /// `provider:branch:update` — a manager holding branch:update (e.g. to
  /// toggle maintenance) does not thereby gain delete authority; that
  /// would silently grant a capability the backend never issued. Defaults
  /// to `false` (fail closed) so a caller that forgets to thread this
  /// through never over-grants Delete.
  final bool isOwner;

  /// Externally-driven controller for the first-time swipe discoverability
  /// hint (`AppSwipeActionHint`). Only ever supplied for the one row the
  /// hint targets — every other row leaves this null and keeps
  /// `AppSwipeActions`'s default self-owned controller.
  final SlidableController? hintController;

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

    // Two independent permission decisions — view (edit swipe → navigation
    // to a read-only-safe details page) and update (maintenance toggle) —
    // one `PermissionBuilder` per decision so each rebuilds only when its
    // own outcome flips. Nesting them is trivial here (three swipes, one
    // row) and keeps the "no raw permission checks in widgets" rule
    // (RBAC Phase 7N) intact — no inline `AuthorizationReader.can(...)`
    // reads anywhere in this file.
    return PermissionBuilder(
      requirement: const PermissionRequirement.single(BranchPermissions.view),
      builder: (context, canEdit) => PermissionBuilder(
        requirement: const PermissionRequirement.single(
          BranchPermissions.update,
        ),
        builder: (context, canToggleMaintenance) => _buildSwipeRow(
          context,
          colors,
          initial,
          canEdit: canEdit,
          canToggleMaintenance: canToggleMaintenance,
        ),
      ),
    );
  }

  Widget _buildSwipeRow(
    BuildContext context,
    AppColors colors,
    String initial, {
    required bool canEdit,
    required bool canToggleMaintenance,
  }) {
    // `isOwner` (the persona flag threaded in via the widget constructor)
    // is captured by this closure — no extra parameter needed here since
    // it's already a field on `this`.
    return AppSwipeActions(
      groupTag: branchSwipeGroupTag,
      controller: hintController,
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
        // TODO(G2): no `provider:branch:delete` permission exists in the
        // backend catalog yet — see the backend-gaps ticket. Delete is
        // therefore **persona-controlled** (owner-only via [isOwner]), not
        // a proxy on `branch:update`: a manager holding `branch:update`
        // (e.g. to toggle maintenance) must NOT thereby gain delete
        // authority — that would silently grant a capability the backend
        // never issued, exactly the "never invent a backend permission"
        // rule this feature is built around. Replace this persona check
        // with a real `PermissionBuilder`/`PermissionGate` on the new
        // permission constant once G2 ships.
        if (isOwner)
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
