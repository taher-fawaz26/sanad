import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/src/presentation/sheet_navigator.dart';
import 'package:sheet_navigation/src/route/sheet_route_settings.dart';

/// Bottom-sheet confirmation for a destructive/warning action — Figma
/// `4715:26601`, `5261:44604`, `5222:44122`, `4715:26593`.
///
/// Pushes [AppConfirmationContent] via [SheetNavigator], resolving to `true`
/// when the action is confirmed, `false` on cancel, or `null` if dismissed.
/// [badgeLabel] renders an optional soft-neutral [AppChip] above the
/// description (e.g. the name of the entity the action applies to).
Future<bool?> showConfirmationSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String actionLabel,
  required String cancelLabel,
  String? badgeLabel,
  AppButtonVariant actionVariant = AppButtonVariant.primary,
  AppButtonIntent actionIntent = AppButtonIntent.standard,
}) {
  return SheetNavigator.push<bool>(
    context,
    Builder(
      builder: (sheetContext) => AppConfirmationContent(
        title: title,
        description: description,
        actionLabel: actionLabel,
        cancelLabel: cancelLabel,
        actionVariant: actionVariant,
        actionIntent: actionIntent,
        badge: badgeLabel == null
            ? null
            : AppChip(label: badgeLabel, tone: AppChipTone.softNeutral),
        onConfirm: () => Navigator.of(sheetContext).pop(true),
        onCancel: () => Navigator.of(sheetContext).pop(false),
      ),
    ),
    settings: const SheetRouteSettings(padChild: false),
  );
}
