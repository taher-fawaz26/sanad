import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';

/// A single resource group in the role form's permission list — Figma
/// `PermissionCard` (`5492:24006`).
///
/// Shows a "selected of total" count and a select-all checkbox in the
/// header; the card border turns teal once every permission in the group
/// is selected.
class PermissionGroupCard extends StatelessWidget {
  const PermissionGroupCard({
    required this.resource,
    required this.permissions,
    required this.selectedIds,
    required this.onToggle,
    super.key,
  });

  final String resource;
  final List<PermissionEntity> permissions;
  final Set<String> selectedIds;
  final ValueChanged<String> onToggle;

  bool get _allSelected =>
      permissions.every((permission) => selectedIds.contains(permission.id));

  int get _selectedCount => permissions
      .where((permission) => selectedIds.contains(permission.id))
      .length;

  void _toggleAll() {
    final shouldSelect = !_allSelected;
    for (final permission in permissions) {
      final isSelected = selectedIds.contains(permission.id);
      if (shouldSelect != isSelected) onToggle(permission.id);
    }
  }

  String get _title => resource.isEmpty
      ? resource
      : '${resource[0].toUpperCase()}${resource.substring(1)}';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final allSelected = _allSelected;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(
          color: allSelected ? colors.primary : colors.gray200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: typography.smallNormal.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: AppSpacing.xs),
                    Text(
                      '$_selectedCount / ${permissions.length}',
                      style: typography.smallNone.copyWith(
                        color: colors.textMuted,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              AppCheckbox(value: allSelected, onChanged: (_) => _toggleAll()),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          const AppDivider(),
          SizedBox(height: AppSpacing.md),
          for (var i = 0; i < permissions.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.md),
            _PermissionItemRow(
              permission: permissions[i],
              selected: selectedIds.contains(permissions[i].id),
              onToggle: onToggle,
            ),
          ],
        ],
      ),
    );
  }
}

class _PermissionItemRow extends StatelessWidget {
  const _PermissionItemRow({
    required this.permission,
    required this.selected,
    required this.onToggle,
  });

  final PermissionEntity permission;
  final bool selected;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return GestureDetector(
      onTap: () => onToggle(permission.id),
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          AppCheckbox(
            value: selected,
            onChanged: (_) => onToggle(permission.id),
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              permission.displayName,
              style: typography.regularNormal.copyWith(
                color: colors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
