import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';

/// Multi-select checklist for the live permission catalog, grouped by
/// [PermissionEntity.resource] (e.g. "branch", "worker") for scanability.
///
/// Composed from [AppCheckbox] — there is no ready-made multi-select list
/// widget in `design_system` yet, so this builds one from the checkbox atom.
class PermissionMultiSelectList extends StatelessWidget {
  const PermissionMultiSelectList({
    required this.permissions,
    required this.selectedIds,
    required this.onToggle,
    super.key,
  });

  final List<PermissionEntity> permissions;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    final grouped = <String, List<PermissionEntity>>{};
    for (final permission in permissions) {
      grouped.putIfAbsent(permission.resource, () => []).add(permission);
    }
    final resources = grouped.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < resources.length; i++) ...[
          if (i > 0) SizedBox(height: AppSpacing.lg),
          Text(
            resources[i],
            style: typography.smallNormal.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          for (final permission in grouped[resources[i]]!)
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: GestureDetector(
                onTap: () => onToggle(permission.id),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    AppCheckbox(
                      value: selectedIds.contains(permission.id),
                      onChanged: (_) => onToggle(permission.id),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        permission.displayName,
                        style: typography.regularNormal.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ],
    );
  }
}
