import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Search + filter row — Figma `4715:26136`. The search field is real,
/// server-backed search (`ServicesListSearchChangedEvent` →
/// `GET /services?search=`), not a navigate-away trigger — Figma shows it
/// inline in the list, not as a separate search screen.
///
/// Status/Type are decorative per Figma but have no backend/BLoC filter
/// param (`GetServicesListParams` only supports `page`/`search`) — `onTap`
/// is exposed so a caller COULD wire a picker, but nothing calls it yet
/// (see audit blockers: no server-side status/type filter exists).
class ServicesFilterBar extends StatelessWidget {
  const ServicesFilterBar({
    super.key,
    this.searchController,
    this.onSearchChanged,
    this.onStatusTap,
    this.onTypeTap,
  });

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onStatusTap;
  final VoidCallback? onTypeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppSearchField(
          controller: searchController,
          variant: AppSearchFieldVariant.bordered,
          hint: 'services.search_hint'.tr(),
          showMicIcon: false,
          onChanged: onSearchChanged,
        ),
        SizedBox(height: AppSpacing.md),
        Row(
          children: [
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
