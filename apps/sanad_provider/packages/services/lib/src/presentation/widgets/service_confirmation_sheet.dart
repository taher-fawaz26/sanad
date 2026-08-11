import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Bottom-sheet confirmation for service actions (pause/resume/edit/delete) —
/// Figma `4715:26601`, `5261:44604`, `5222:44122`, `4715:26593`.
///
/// Mirrors `workers`' `showWorkerConfirmationSheet` (same
/// `SheetNavigator` + [AppConfirmationContent] pattern) with an optional
/// service-name chip badge, matching the Figma sheets exactly instead of the
/// generic centered `showAppPopover`.
Future<bool?> showServiceConfirmationSheet({
  required BuildContext context,
  required String title,
  required String description,
  required String actionLabel,
  required String cancelLabel,
  String? serviceName,
  AppButtonType actionType = AppButtonType.primary,
  bool destructive = false,
}) {
  return SheetNavigator.push<bool>(
    context,
    AppConfirmationContent(
      title: title,
      description: description,
      actionLabel: actionLabel,
      cancelLabel: cancelLabel,
      actionType: actionType,
      destructive: destructive,
      badge: serviceName == null
          ? null
          : AppChip(label: serviceName, tone: AppChipTone.softNeutral),
      onConfirm: () => Navigator.of(context).pop(true),
      onCancel: () => Navigator.of(context).pop(false),
    ),
    settings: const SheetRouteSettings(
      sheetSize: SheetSize.expanded,
      padChild: false,
    ),
  );
}
