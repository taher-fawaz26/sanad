import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/presentation/dialogs/permission_dialog.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';

/// Shows a bottom-sheet explaining why the app needs a permission before the
/// OS prompt is displayed.
///
/// Returns `true` if the user chose to proceed, `false` / `null` otherwise.
class PermissionRationaleDialog {
  const PermissionRationaleDialog._();

  /// Shows the rationale sheet and returns whether the user accepted.
  ///
  /// [explanation] overrides the theme-resolved explanation for
  /// [permissionType].
  static Future<bool> show({
    required BuildContext context,
    required PermissionType permissionType,
    required PermissionTheme theme,
    PermissionExplanation? explanation,
  }) async {
    final resolved = explanation ?? theme.explanationFor(permissionType);

    final result = await showAppBottomSheet<bool>(
      context: context,
      child: PermissionDialogContent(
        explanation: resolved,
        theme: theme,
        primaryLabel: resolved.allowLabel ?? theme.texts.allowButtonLabel,
        primaryAction: () => Navigator.of(context).pop(true),
        secondaryLabel: resolved.denyLabel ?? theme.texts.denyButtonLabel,
        secondaryAction: () => Navigator.of(context).pop(false),
      ),
    );

    return result ?? false;
  }
}
