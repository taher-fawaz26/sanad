import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:workers/workers.dart' show SheetActionRow;

/// The "more" menu opened from a role card — Figma `Views / Bottom Sheets`
/// (`5492:23946`): View Details / Edit Information / Delete.
///
/// Edit and Delete are hidden for system role templates, which stay
/// read-only in this app (matches the existing list behaviour).
Future<void> showRoleActionsBottomSheet({
  required BuildContext context,
  required RoleEntity role,
  required VoidCallback onViewDetails,
  VoidCallback? onEdit,
  VoidCallback? onDelete,
}) {
  return SheetNavigator.push<void>(
    context,
    _RoleActionsSheetBody(
      role: role,
      onViewDetails: onViewDetails,
      onEdit: onEdit,
      onDelete: onDelete,
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.content,
      padChild: false,
    ),
  );
}

class _RoleActionsSheetBody extends StatelessWidget {
  const _RoleActionsSheetBody({
    required this.role,
    required this.onViewDetails,
    this.onEdit,
    this.onDelete,
  });

  final RoleEntity role;
  final VoidCallback onViewDetails;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTableRow(
          title: 'provider_rbac.action_view_details'.tr(),
          leading: AppTableLeading.icon,
          leadingIcon: AppSvgPicture.asset(
            AppSvgs.branchView,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(colors.textPrimary, BlendMode.srcIn),
          ),
          onTap: () {
            Navigator.of(context).pop();
            onViewDetails();
          },
        ),
        if (onEdit != null)
          AppTableRow(
            title: 'provider_rbac.action_edit'.tr(),
            leading: AppTableLeading.icon,
            leadingIcon: AppSvgPicture.asset(
              AppSvgs.branchEdit,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                colors.textPrimary,
                BlendMode.srcIn,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              onEdit?.call();
            },
          ),
        if (onDelete != null) ...[
          const AppDivider(),
          SheetActionRow(
            label: 'common.delete'.tr(),
            svgAsset: AppSvgs.trashBold,
            color: colors.error,
            onTap: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
          ),
        ],
      ],
    );
  }
}
