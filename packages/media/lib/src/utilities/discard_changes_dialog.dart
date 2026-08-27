import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Confirms the user wants to abandon in-progress edits. Returns `true` when
/// they choose to discard.
Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final confirmed = await showConfirmationSheet(
    context: context,
    title: 'common.discard_title'.tr(),
    description: 'media.discard_message'.tr(),
    actionLabel: 'common.discard'.tr(),
    cancelLabel: 'common.keep_editing'.tr(),
    actionIntent: AppButtonIntent.destructive,
  );
  return confirmed ?? false;
}
