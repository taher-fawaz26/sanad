import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

/// A single role card in the roles list — Figma `Role Card` (`5494:22710`).
///
/// System role templates show paired "Default"/"System" badges and a
/// "Read-only" footer pill; custom roles show a single "Custom" badge.
class RoleCard extends StatelessWidget {
  const RoleCard({required this.role, this.onMoreTap, super.key});

  final RoleEntity role;
  final VoidCallback? onMoreTap;

  static const _visibleChipCount = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final description = role.description?.trim() ?? '';
    final permissions = role.permissions;
    final visibleChips = permissions.take(_visibleChipCount).toList();
    final overflowCount = permissions.length - visibleChips.length;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: colors.gray200),
        borderRadius: BorderRadius.circular(responsiveDimension(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    Text(
                      role.displayName,
                      style: typography.regularNormal.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    for (final badge in _badges()) badge,
                  ],
                ),
              ),
              GestureDetector(
                onTap: onMoreTap,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: colors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
                height: 18 / 13,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.md),
          const AppDivider(),
          SizedBox(height: AppSpacing.md),
          Text(
            'provider_rbac.permission_count'.tr(
              namedArgs: {'count': '${permissions.length}'},
            ),
            style: typography.smallNormal.copyWith(
              color: colors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              for (final permission in visibleChips)
                _PermissionChip(label: permission.displayName),
              if (overflowCount > 0) _OverflowBadge(count: overflowCount),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          const AppDivider(),
          SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'provider_rbac.applies_to'.tr(),
                      style: typography.smallNone.copyWith(
                        color: colors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _appliesToLabel(role.userType),
                      style: typography.smallNormal.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (role.isSystem)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.gray200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'provider_rbac.read_only'.tr(),
                    style: typography.smallNone.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _badges() {
    if (role.isSystem) {
      return [
        _Badge(
          label: 'provider_rbac.badge_default'.tr(),
          tone: _BadgeTone.neutral,
        ),
        _Badge(
          label: 'provider_rbac.badge_system'.tr(),
          tone: _BadgeTone.success,
        ),
      ];
    }
    return [
      _Badge(
        label: 'provider_rbac.badge_custom'.tr(),
        tone: _BadgeTone.error,
      ),
    ];
  }

  String _appliesToLabel(RolePersonaType type) => switch (type) {
    RolePersonaType.admin => 'provider_rbac.applies_to_admin'.tr(),
    RolePersonaType.client => 'provider_rbac.applies_to_client'.tr(),
    RolePersonaType.individualProvider =>
      'provider_rbac.applies_to_individual_provider'.tr(),
    RolePersonaType.companyProvider =>
      'provider_rbac.applies_to_company_provider'.tr(),
    RolePersonaType.worker => 'provider_rbac.applies_to_worker'.tr(),
  };
}

enum _BadgeTone { neutral, success, error }

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.tone});

  final String label;
  final _BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final (background, foreground) = switch (tone) {
      _BadgeTone.neutral => (colors.gray100, colors.gray700),
      _BadgeTone.success => (
        colors.successContainer,
        colors.onSuccessContainer,
      ),
      _BadgeTone.error => (colors.errorContainer, colors.onErrorContainer),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: typography.smallNone.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _PermissionChip extends StatelessWidget {
  const _PermissionChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.successContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: typography.regularNormal.copyWith(
          color: colors.onSuccessContainer,
          fontSize: 14,
        ),
      ),
    );
  }
}

class _OverflowBadge extends StatelessWidget {
  const _OverflowBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.gray100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        '+$count',
        style: typography.smallNone.copyWith(
          color: colors.gray700,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      ),
    );
  }
}
