import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Search + filter row — Figma `4715:26136`. The search field is real,
/// server-backed search (`ServicesListSearchChangedEvent` →
/// `GET /services?search=`), not a navigate-away trigger — Figma shows it
/// inline in the list, not as a separate search screen.
///
/// Status is a real server-side filter (`GET /provider-services?status=`,
/// `active`/`inactive`/`all`) — [onStatusTap] opens a picker and
/// [statusLabel] reflects the current selection.
///
/// Type has no backend query param to filter on (confirmed against the live
/// API contract — `GET /provider-services` only accepts `page`/`limit`/
/// `search`/`status`) — [onTypeTap] is intentionally left unset by every
/// caller so the dropdown stays visible but inert until the backend adds
/// one. Do not fake client-side filtering for it.
class ServicesFilterBar extends StatelessWidget {
  const ServicesFilterBar({
    super.key,
    this.showSearch = true,
    this.searchController,
    this.onSearchChanged,
    this.statusLabel,
    this.onStatusTap,
    this.onTypeTap,
  });

  /// Whether to render the search field. `false` when the search field is
  /// hosted elsewhere instead (e.g. a pinned header above a collapsing
  /// section that contains just the status/type filter row).
  final bool showSearch;

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  /// Label shown on the Status dropdown — pass the current filter's display
  /// text (e.g. "Active") so the selection is visible; defaults to the
  /// generic "Status" placeholder when unset.
  final String? statusLabel;
  final VoidCallback? onStatusTap;
  final VoidCallback? onTypeTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSearch) ...[
          AppSearchField(
            controller: searchController,
            variant: AppSearchFieldVariant.bordered,
            hint: 'services.search_hint'.tr(),
            showMicIcon: false,
            onChanged: onSearchChanged,
          ),
          SizedBox(height: AppSpacing.md),
        ],
        Row(
          children: [
            Expanded(
              child: _FilterDropdown(
                label: statusLabel ?? 'services.filter_status'.tr(),
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
