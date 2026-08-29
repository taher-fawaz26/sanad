import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/cubit/edit_category_cubit.dart';
import 'package:shared_ui/shared_ui.dart';
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
/// The multi-select draft lives in [EditCategoryCubit] (widget-scoped, no
/// external dependencies); this widget only renders it and pops with the
/// confirmed [Set<String>] of selected IDs when the user taps Save.
class EditCategoryBottomSheet extends StatelessWidget {
  const EditCategoryBottomSheet({
    required this.categories,
    super.key,
    this.initialSelectedIds = const {},
  });

  final List<CategoryOption> categories;
  final Set<String> initialSelectedIds;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditCategoryCubit(initialSelectedIds: initialSelectedIds),
      child: _EditCategoryBottomSheetBody(categories: categories),
    );
  }
}

class _EditCategoryBottomSheetBody extends StatelessWidget {
  const _EditCategoryBottomSheetBody({required this.categories});

  final List<CategoryOption> categories;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxListHeight = MediaQuery.sizeOf(context).height * 0.5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DragHandle(color: colors.border),
        SizedBox(height: AppSpacing.md),
        SettingsSheetTitle(title: 'settings.section_category'.tr()),
        SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxListHeight),
          child:
              BlocSelector<
                EditCategoryCubit,
                EditCategorySelection,
                Set<String>
              >(
                selector: (state) => state.selectedIds,
                builder: (context, selectedIds) => ListView.separated(
                  shrinkWrap: true,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const AppDivider(),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final isSelected = selectedIds.contains(category.id);
                    return AppTableRow(
                      title: category.name,
                      trailing: AppTableTrailing.icon,
                      trailingIcon: AppCheckbox(
                        value: isSelected,
                        onChanged: (_) => context
                            .read<EditCategoryCubit>()
                            .toggle(category.id),
                      ),
                      onTap: () =>
                          context.read<EditCategoryCubit>().toggle(category.id),
                    );
                  },
                ),
              ),
        ),
        const AppDivider(),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.sm,
            AppSpacing.xl,
            AppSpacing.sm,
          ),
          child: BlocSelector<EditCategoryCubit, EditCategorySelection, bool>(
            selector: (state) => state.selectedIds.isEmpty,
            builder: (context, isEmpty) => AppButton(
              label: 'common.save'.tr(),
              onPressed: isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                      Set<String>.of(
                        context.read<EditCategoryCubit>().state.selectedIds,
                      ),
                    ),
            ),
          ),
        ),
      ],
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
