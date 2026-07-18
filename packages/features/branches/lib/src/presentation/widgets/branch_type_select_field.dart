import 'package:branches/src/domain/entities/branch_type.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Branch type picker backed by [BranchType] enum values.
class BranchTypeSelectField extends StatelessWidget {
  const BranchTypeSelectField({
    required this.selectedType,
    required this.onTypeSelected,
    super.key,
  });

  final BranchType selectedType;
  final ValueChanged<BranchType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return AppSelectField(
      label: 'branches.add_branch.branch_type'.tr(),
      value: _localizedLabel(selectedType),
      hint: 'branches.add_branch.branch_type_hint'.tr(),
      onTap: () => _openPicker(context),
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    await showAppActionSheet<void>(
      context: context,
      title: 'branches.add_branch.branch_type'.tr(),
      cancelLabel: 'branches.add_branch.cancel'.tr(),
      items: BranchType.values
          .map(
            (type) => AppActionSheetItem(
              label: _localizedLabel(type),
              onTap: () => onTypeSelected(type),
            ),
          )
          .toList(),
    );
  }

  String _localizedLabel(BranchType type) => switch (type) {
    BranchType.mainBranch => 'branches.add_branch.branch_type_main_branch'.tr(),
    BranchType.headquarters =>
      'branches.add_branch.branch_type_headquarters'.tr(),
    BranchType.mainStore => 'branches.add_branch.branch_type_main_store'.tr(),
    BranchType.warehouse => 'branches.add_branch.branch_type_warehouse'.tr(),
  };
}
