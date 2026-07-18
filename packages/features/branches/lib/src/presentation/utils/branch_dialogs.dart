import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Figma discard changes dialog (`1517:9645`).
Future<bool?> showDiscardBranchChangesDialog(BuildContext context) {
  return showAppPopover<bool>(
    context: context,
    title: 'branches.add_branch.discard_title'.tr(),
    description: 'branches.add_branch.discard_description'.tr(),
    imageLayout: AppDialogImageLayout.iconSmall,
    featureIconColor: AppFeatureIconColor.warning,
    featureIconBackgroundColor: const Color(0xFFFFF3CD),
    actions: AppPopoverActions.dual,
    primaryLabel: 'branches.add_branch.discard_confirm'.tr(),
    primaryDestructive: true,
    onPrimary: () => Navigator.of(context).pop(true),
    secondaryLabel: 'branches.add_branch.discard_keep_editing'.tr(),
    secondaryAsTextLink: true,
    onSecondary: () => Navigator.of(context).pop(false),
    barrierDismissible: true,
  );
}

/// Figma submit loading dialog (`1517:9657`).
Future<void> showBranchSubmitLoadingDialog(BuildContext context) {
  return showAppPopover<void>(
    context: context,
    title: 'branches.add_branch.loading_title'.tr(),
    description: 'branches.add_branch.loading_description'.tr(),
    actions: AppPopoverActions.loading,
    barrierDismissible: false,
  );
}
