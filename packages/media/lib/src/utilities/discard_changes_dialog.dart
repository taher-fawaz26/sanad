import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Confirms the user wants to abandon in-progress edits. Returns `true` when
/// they choose to discard.
Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final colors = context.appColors;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text('common.discard_title'.tr()),
      content: Text('media.discard_message'.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text('common.keep_editing'.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'common.discard'.tr(),
            style: TextStyle(color: colors.error),
          ),
        ),
      ],
    ),
  );
  return result ?? false;
}
