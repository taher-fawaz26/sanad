import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// A selectable category option shown inside [EditCategoryBottomSheet].
@immutable
class CategoryOption {
  const CategoryOption({required this.id, required this.name});

  final String id;
  final String name;
}

/// Shows the category multi-select bottom sheet and returns the confirmed
/// selection, or null when the user dismisses without saving.
///
/// [categories] is the full list of available options.
/// [initialSelectedIds] pre-checks the currently active categories.
Future<Set<String>?> showEditCategoryBottomSheet({
  required BuildContext context,
  required List<CategoryOption> categories,
  Set<String> initialSelectedIds = const {},
}) {
  // AppActionSheet renders its own drag handle, padding, and surface — don't
  // double them up with SheetScaffold's chrome.
  return SheetNavigator.push<Set<String>>(
    context,
    EditCategoryBottomSheet(
      categories: categories,
      initialSelectedIds: initialSelectedIds,
    ),
    settings: const SheetRouteSettings(
      enableDrag: false,
      padChild: false,
    ),
  );
}

/// Bottom sheet for editing organization category and classification.
///
/// Manages multi-select state internally and pops with the confirmed
/// [Set<String>] of selected IDs when the user taps Save.
class EditCategoryBottomSheet extends StatefulWidget {
  const EditCategoryBottomSheet({
    required this.categories,
    super.key,
    this.initialSelectedIds = const {},
  });

  final List<CategoryOption> categories;
  final Set<String> initialSelectedIds;

  @override
  State<EditCategoryBottomSheet> createState() =>
      _EditCategoryBottomSheetState();
}

class _EditCategoryBottomSheetState extends State<EditCategoryBottomSheet> {
  late final Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = Set.from(widget.initialSelectedIds);
  }

  void _toggle(String id) => setState(() {
    _selectedIds.contains(id) ? _selectedIds.remove(id) : _selectedIds.add(id);
  });

  void _save() => Navigator.of(context).pop(Set<String>.from(_selectedIds));

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;

    return AppActionSheet(
      showCancel: false,
      footer: AppButton(
        label: 'common.save'.tr(),
        onPressed: _selectedIds.isEmpty ? null : _save,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DragHandle(color: colors.border),
          SizedBox(height: AppSpacing.md),
          _SheetHeader(colors: colors, typography: typography),
          SizedBox(height: AppSpacing.md),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxListHeight),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.categories.length,
              separatorBuilder: (_, _) => const AppDivider(),
              itemBuilder: (context, index) {
                final category = widget.categories[index];
                final isSelected = _selectedIds.contains(category.id);
                return AppTableRow(
                  title: category.name,
                  trailing: AppTableTrailing.icon,
                  trailingIcon: AppCheckbox(
                    value: isSelected,
                    onChanged: (_) => _toggle(category.id),
                  ),
                  onTap: () => _toggle(category.id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.colors, required this.typography});

  final AppColors colors;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.tools,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'settings.section_category'.tr(),
          textAlign: TextAlign.center,
          style: typography.title3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
