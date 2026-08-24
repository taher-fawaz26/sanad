import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/presentation/utils/role_display_name.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Roles multi-select bottom sheet for the Add Member "Rules" field —
/// mirrors `services`' `showSelectServiceActionSheet` (same [AppSelectSheet]
/// pattern: searchable, multi-select, Confirm button).
///
/// [mandatoryRoleId], when non-null, is always seeded into the selection and
/// rendered as a locked, non-toggleable row (disabled checkbox, lock badge)
/// so the mandatory baseline role can never be unchecked from the sheet.
Future<List<RoleEntity>?> showSelectRolesActionSheet({
  required BuildContext context,
  required Future<List<RoleEntity>> Function() loadItems,
  required Set<String> initialSelectedIds,
  String? mandatoryRoleId,
}) => SheetNavigator.push<List<RoleEntity>>(
  context,
  AppSelectSheet<RoleEntity>(
    confirmLabel: 'common.confirm'.tr(),
    searchHint: 'common.search_hint'.tr(),
    searchVariant: AppSearchFieldVariant.bordered,
    getId: (role) => role.id,
    searchFilter: (role, query) =>
        role.displayName.toLowerCase().contains(query),
    initialSelectedIds: initialSelectedIds,
    loadItems: loadItems,
    errorTextBuilder: (e) => e is Failure ? e.message : e.toString(),
    retryLabel: 'common.retry'.tr(),
    itemBuilder: (context, role, isSelected, onTap) {
      final isLocked = role.id == mandatoryRoleId;
      return AppTableRow(
        title: role.localizedDisplayName(),
        trailing: AppTableTrailing.icon,
        trailingIcon: isLocked
            ? Icon(
                Icons.lock_outline,
                size: 16,
                color: context.appColors.textMuted,
              )
            : AppCheckbox(value: isSelected, onChanged: (_) => onTap()),
        onTap: isLocked ? null : onTap,
      );
    },
  ),
  settings: SheetRouteSettings(
    title: 'workers.add_worker.roles_label'.tr(),
    padChild: false,
  ),
);
