import 'package:flutter/material.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/presentation/dialogs/permission_dialog.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

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

    await SheetNavigator.push<void>(
      context,
      // `sheetContext` (not the outer `context`) is what the pop calls must
      // use — see the matching comment in `PermissionRationaleDialog.show`.
      Builder(
        builder: (sheetContext) => PermissionDialogContent(
          explanation: resolved,
          theme: theme,
          primaryLabel:
              resolved.openSettingsLabel ?? theme.texts.openSettingsButtonLabel,
          primaryAction: () {
            Navigator.of(sheetContext).pop();
            onOpenSettings();
          },
          secondaryLabel: resolved.cancelLabel ?? theme.texts.cancelButtonLabel,
          secondaryAction: () => Navigator.of(sheetContext).pop(),
        ),
      ),
      settings: const SheetRouteSettings(
        barrierColor: Colors.transparent,
        // See `PermissionRationaleDialog.show` — this sheet always pops
        // itself before anything else happens, so it must never morph to
        // fullscreen from a route pushed while it's still exiting.
        expandPreviousToFullscreen: false,
      ),
    );
  }
}
