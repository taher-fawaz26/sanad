import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/presentation/dialogs/permission_dialog.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';

/// Shows a bottom-sheet informing the user that the permission was permanently
/// denied and offering a shortcut to the app's system settings.
class PermissionSettingsDialog {
  const PermissionSettingsDialog._();

  /// Shows the settings redirect sheet.
  ///
  /// [onOpenSettings] is called when the user taps "Open Settings".
  /// [explanation] overrides the theme-resolved explanation; when omitted the
  /// settings-specific copy from the theme is used.
  static Future<void> show({
    required BuildContext context,
    required PermissionType permissionType,
    required PermissionTheme theme,
    required Future<bool> Function() onOpenSettings,
    PermissionExplanation? explanation,
  }) async {
    // Settings sheet keeps its own title/message but reuses the permission's
    // icon so it stays visually consistent with the rationale sheet.
    final resolved =
        explanation ??
        PermissionExplanation(
          title: theme.texts.settingsTitle,
          description: theme.texts.settingsMessage,
          icon: theme.icons.forType(permissionType),
        );

    await showAppBottomSheet<void>(
      context: context,
      child: PermissionDialogContent(
        explanation: resolved,
        theme: theme,
        primaryLabel: theme.texts.openSettingsButtonLabel,
        primaryAction: () {
          Navigator.of(context).pop();
          onOpenSettings();
        },
        secondaryLabel: theme.texts.cancelButtonLabel,
        secondaryAction: () => Navigator.of(context).pop(),
      ),
    );
  }
}
