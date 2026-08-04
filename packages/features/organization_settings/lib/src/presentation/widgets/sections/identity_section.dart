import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_section_card.dart';

/// View-mode section for organization identity fields.
///
/// Exposes an edit action that will open the identity bottom sheet.
class IdentitySection extends StatelessWidget {
  const IdentitySection({
    super.key,
    this.businessDescription,
    this.onEdit,
    this.onEnhanceWithAi,
  });

  final String? businessDescription;
  final VoidCallback? onEdit;
  final VoidCallback? onEnhanceWithAi;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return SettingsSectionCard(
      title: 'settings.section_identity'.tr(),
      onEdit: onEdit,
      child: _BusinessDescriptionField(
        description: businessDescription,
        onEnhanceWithAi: onEnhanceWithAi,
        colors: colors,
        typography: typography,
      ),
    );
  }
}

class _BusinessDescriptionField extends StatelessWidget {
  const _BusinessDescriptionField({
    required this.colors,
    required this.typography,
    this.description,
    this.onEnhanceWithAi,
  });

  final String? description;
  final VoidCallback? onEnhanceWithAi;
  final AppColors colors;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpacing.xs,
      children: [
        Text(
          'settings.business_description'.tr(),
          style: typography.smallNormal.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.xxl,
            children: [
              if (description != null)
                Text(
                  description!,
                  style: typography.smallNormal.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              AppEnhanceWithAiButton(
                label: 'settings.enhance_with_ai'.tr(),
                onTap: onEnhanceWithAi,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
