import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Search + filter row — Figma `4715:26136`. The search field is real,
/// server-backed search (`ServicesListSearchChangedEvent` →
/// `GET /services?search=`), not a navigate-away trigger — Figma shows it
/// inline in the list, not as a separate search screen.
///
/// Status is a real server-side filter (`GET /provider-services?status=`,
/// `active`/`inactive`/`all`) — [onStatusTap] opens a picker and
/// [statusLabel] reflects the current selection.
///
/// Category is a real, but client-side, filter (`GET /provider-services` has
/// no `categoryId` query param — confirmed against the live API contract) —
/// its options are the unique `service.category` values already present in
/// the currently-loaded page, deduplicated by `category.id`. [onCategoryTap]
/// opens a picker and [categoryLabel] reflects the current selection.
class ServicesFilterBar extends StatelessWidget {
  const ServicesFilterBar({
    super.key,
    this.showSearch = true,
    this.searchController,
    this.onSearchChanged,
    this.statusLabel,
    this.onStatusTap,
    this.categoryLabel,
    this.onCategoryTap,
  });

  /// Whether to render the search field. `false` when the search field is
  /// hosted elsewhere instead (e.g. a pinned header above a collapsing
  /// section that contains just the status/category filter row).
  final bool showSearch;

  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;

  /// Label shown on the Status dropdown — pass the current filter's display
  /// text (e.g. "Active") so the selection is visible; defaults to the
  /// generic "Status" placeholder when unset.
  final String? statusLabel;
  final VoidCallback? onStatusTap;

  /// Label shown on the Category dropdown — pass the selected category's
  /// name so the selection is visible; defaults to the generic "Category"
  /// placeholder when unset.
  final String? categoryLabel;
  final VoidCallback? onCategoryTap;

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
              child: AppFilterField<Never>(
                placeholder: statusLabel ?? 'services.filter_status'.tr(),
                options: const [],
                onTap: onStatusTap,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            Expanded(
              child: AppFilterField<Never>(
                placeholder: categoryLabel ?? 'services.filter_category'.tr(),
                options: const [],
                onTap: onCategoryTap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
