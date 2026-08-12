import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider_rbac/src/domain/entities/permission_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_entity.dart';
import 'package:provider_rbac/src/domain/entities/role_persona_type.dart';

/// Read-only role details — Figma `view details` (`5673:28445`).
class RoleDetailsPage extends StatelessWidget {
  const RoleDetailsPage({required this.role, super.key});

  final RoleEntity role;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: 'provider_rbac.details_title'.tr(),
              showBackButton: true,
              onLeadingTap: () => context.pop(),
              trailing: AppNotificationIcon(onTap: () {}),
              trailingAction: AppNavBarTrailingAction.icon,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _HeaderCard(role: role),
                    SizedBox(height: AppSpacing.md),
                    _PermissionsCard(permissions: role.permissions),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.role});

  final RoleEntity role;

  String _appliesToLabel(RolePersonaType type) => switch (type) {
    RolePersonaType.admin => 'provider_rbac.applies_to_admin'.tr(),
    RolePersonaType.client => 'provider_rbac.applies_to_client'.tr(),
    RolePersonaType.individualProvider =>
      'provider_rbac.applies_to_individual_provider'.tr(),
    RolePersonaType.companyProvider =>
      'provider_rbac.applies_to_company_provider'.tr(),
    RolePersonaType.worker => 'provider_rbac.applies_to_worker'.tr(),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final description = role.description?.trim() ?? '';

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.gray200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            role.displayName,
            style: typography.title2.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (description.isNotEmpty) ...[
            SizedBox(height: AppSpacing.sm),
            Text(
              description,
              style: typography.regularNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              if (role.isSystem) ...[
                _Badge(
                  label: 'provider_rbac.badge_default'.tr(),
                  background: colors.gray100,
                  foreground: colors.gray700,
                ),
                _Badge(
                  label: 'provider_rbac.badge_system'.tr(),
                  background: colors.successContainer,
                  foreground: colors.onSuccessContainer,
                ),
              ] else
                _Badge(
                  label: 'provider_rbac.badge_custom'.tr(),
                  background: colors.errorContainer,
                  foreground: colors.onErrorContainer,
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          const AppDivider(),
          SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.successContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: AppSvgPicture.asset(
                  AppSvgs.users2,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    colors.onSuccessContainer,
                    BlendMode.srcIn,
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'provider_rbac.applies_to'.tr(),
                    style: typography.smallNone.copyWith(
                      color: colors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _appliesToLabel(role.userType),
                    style: typography.regularNormal.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    final typography = context.appTypography;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
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

class _PermissionsCard extends StatelessWidget {
  const _PermissionsCard({required this.permissions});

  final List<PermissionEntity> permissions;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.gray200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'provider_rbac.assigned_permissions'.tr(
              namedArgs: {'count': '${permissions.length}'},
            ),
            style: typography.regularNormal.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          for (var i = 0; i < permissions.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.sm),
            _PermissionRow(label: permissions[i].displayName),
          ],
        ],
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: colors.gray200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(Icons.check, size: 16, color: colors.white),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              label,
              style: typography.regularNormal.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
