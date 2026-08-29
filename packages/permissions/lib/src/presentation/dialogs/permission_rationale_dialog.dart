import 'package:flutter/material.dart';
import 'package:permissions/src/domain/enums/permission_type.dart';
import 'package:permissions/src/presentation/dialogs/permission_dialog.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

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

    final result = await SheetNavigator.push<bool>(
      context,
      // `sheetContext` (not the outer `context`) is what the pop calls must
      // use: this sheet lives on the root navigator (`SheetNavigator.push`
      // always targets `rootNavigator: true`), but the caller's `context`
      // (e.g. a page nested inside a shell route) can resolve
      // `Navigator.of(context)` to a *different*, nearer navigator. Popping
      // that nearer navigator instead of this sheet was popping the
      // underlying page — see the identical, already-correct pattern in
      // `showConfirmationSheet`.
      Builder(
        builder: (sheetContext) => PermissionDialogContent(
          explanation: resolved,
          theme: theme,
          primaryLabel: resolved.allowLabel ?? theme.texts.allowButtonLabel,
          primaryAction: () => Navigator.of(sheetContext).pop(true),
          secondaryLabel: resolved.denyLabel ?? theme.texts.denyButtonLabel,
          secondaryAction: () => Navigator.of(sheetContext).pop(false),
        ),
      ),
      settings: const SheetRouteSettings(
        barrierColor: Colors.transparent,
        // This sheet always ends by popping itself before anything else
        // happens (grant/deny/dismiss) — it must never morph to fullscreen
        // because a route was pushed while it was still finishing its own
        // exit transition (Route.didPop completes the awaited Future
        // synchronously, well before the reverse animation/finalizeRoute
        // actually removes it from the Navigator).
        expandPreviousToFullscreen: false,
      ),
    );

    return result ?? false;
  }
}
