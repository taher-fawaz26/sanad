import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/components/settings_category_field_view.dart';
import 'package:shared_ui/shared_ui.dart';

/// View-mode section for organization category and classification.
///
/// Exposes an edit action that opens [EditCategoryBottomSheet].
class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    this.selectedCategories = const [],
    this.onEdit,
  });

  final List<String> selectedCategories;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_category'.tr(),
      onEdit: onEdit,
      child: SettingsCategoryFieldView(
        selectedCategories: selectedCategories,
      ),
    );
  }
}
