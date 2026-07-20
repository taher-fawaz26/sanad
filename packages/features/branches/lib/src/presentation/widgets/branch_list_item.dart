import 'package:branches/src/domain/entities/branch_entity.dart';
import 'package:branches/src/presentation/utils/branch_type_formatter.dart';
import 'package:branches/src/presentation/widgets/branch_actions_bottom_sheet.dart';
import 'package:branches/src/routes/branch_routes.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A single branch row — Figma branch card (`347:14361`).
///
/// Shared by the main branches list and the search bottom sheet so both
/// stay visually identical.
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

    return AppEntityListItem(
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
      trailing: Semantics(
        label: 'branches.more_actions'.tr(),
        child: AppIconButton(
          icon: Icons.more_vert,
          iconColor: colors.textPrimary,
          onTap: () => showBranchActionsBottomSheet(
            context: context,
            branch: branch,
          ),
        ),
      ),
      onTap: onTap ?? () => context.push(BranchRoutes.detailsFor(branch.id)),
    );
  }
}
