import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Search + filter row — Figma `4715:26136`.
class ServicesFilterBar extends StatelessWidget {
  const ServicesFilterBar({
    super.key,
    this.onSearchTap,
    this.onFilterTap,
    this.onStatusTap,
    this.onTypeTap,
  });

  final VoidCallback? onSearchTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onStatusTap;
  final VoidCallback? onTypeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSearchField(
          variant: AppSearchFieldVariant.bordered,
          hint: 'services.search_hint'.tr(),
          showMicIcon: false,
          readOnly: true,
          onTap: onSearchTap,
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
            _FilterIconButton(onTap: onFilterTap),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _FilterDropdown(
                label: 'services.filter_status'.tr(),
                onTap: onStatusTap,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _FilterDropdown(
                label: 'services.filter_type'.tr(),
                onTap: onTypeTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FilterIconButton extends StatelessWidget {
  const _FilterIconButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = responsiveDimension(44);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimension.radiusSm),
            border: Border.all(color: colors.palettes.dark.shade200),
            boxShadow: AppShadows.xs,
          ),
          child: AppSvgPicture.asset(
            AppSvgs.filterLines,
            width: AppDimension.iconSm,
            height: AppDimension.iconSm,
            colorFilter: ColorFilter.mode(
              colors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  const _FilterDropdown({required this.label, this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final height = responsiveDimension(44);

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimension.radiusSm),
            border: Border.all(color: colors.palettes.sky.shade200),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: typography
                      .medium(typography.smallTight)
                      .copyWith(color: colors.textPrimary),
                ),
              ),
              AppSvgPicture.asset(
                AppSvgs.chevronDown,
                width: AppDimension.iconMd,
                height: AppDimension.iconMd,
                colorFilter: ColorFilter.mode(
                  colors.textSecondary,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
