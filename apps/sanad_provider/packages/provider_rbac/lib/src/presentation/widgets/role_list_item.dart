import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';

/// A single row in the roles & permissions list.
///
/// System role templates are read-only (no trailing action); custom roles
/// get a chevron to open the edit form.
class RoleListItem extends StatelessWidget {
  const RoleListItem({required this.role, this.onTap, super.key});

  final RoleEntity role;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final permissionCount = role.permissions.length;
    final caption = role.isSystem
        ? 'provider_rbac.system_role_caption'.tr(
            namedArgs: {'count': '$permissionCount'},
          )
        : 'provider_rbac.custom_role_caption'.tr(
            namedArgs: {'count': '$permissionCount'},
          );

    return AppTableRow(
      title: role.displayName,
      caption: caption,
      trailing: role.isSystem ? AppTableTrailing.none : AppTableTrailing.icon,
      trailingIcon: role.isSystem
          ? null
          : Icon(Icons.chevron_right, size: 18, color: colors.gray400),
      onTap: role.isSystem ? null : onTap,
    );
  }
}
