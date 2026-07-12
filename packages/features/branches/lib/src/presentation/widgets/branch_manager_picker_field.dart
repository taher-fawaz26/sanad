import 'package:branches/src/domain/entities/branch_manager_entity.dart';
import 'package:branches/src/presentation/widgets/branch_person_select_field.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Branch manager picker backed by a static workers list for now.
class BranchManagerPickerField extends StatelessWidget {
  const BranchManagerPickerField({
    required this.managers,
    required this.selectedManager,
    required this.onManagerSelected,
    super.key,
  });

  final List<BranchManagerEntity> managers;
  final BranchManagerEntity? selectedManager;
  final ValueChanged<BranchManagerEntity> onManagerSelected;

  @override
  Widget build(BuildContext context) {
    return BranchPersonSelectField(
      label: 'branches.add_branch.branch_manager'.tr(),
      value: selectedManager?.fullName,
      hint: 'branches.add_branch.branch_manager_hint'.tr(),
      avatar: selectedManager == null
          ? null
          : AppAvatar(
              initials: selectedManager!.initials,
              size: AppAvatarSize.small,
            ),
      onTap: managers.isEmpty ? null : () => _openPicker(context),
      enabled: managers.isNotEmpty,
    );
  }

  Future<void> _openPicker(BuildContext context) async {
    await showAppActionSheet(
      context: context,
      title: 'branches.add_branch.branch_manager'.tr(),
      cancelLabel: 'branches.add_branch.cancel'.tr(),
      items: managers
          .map(
            (manager) => AppActionSheetItem(
              label: manager.fullName,
              leading: AppAvatar(
                initials: manager.initials,
                size: AppAvatarSize.small,
              ),
              onTap: () => onManagerSelected(manager),
            ),
          )
          .toList(),
    );
  }
}
