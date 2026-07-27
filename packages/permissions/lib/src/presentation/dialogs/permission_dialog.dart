import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:permissions/src/theme/permission_explanation.dart';
import 'package:permissions/src/theme/permission_theme.dart';

/// Base content widget for all permission bottom-sheets.
///
/// Shows a centred icon, a title, a descriptive message, and a pair of action
/// buttons. Concrete dialogs ([PermissionRationaleDialog],
/// [PermissionSettingsDialog]) compose this widget with a
/// [PermissionExplanation] and callbacks.
class PermissionDialogContent extends StatelessWidget {
  const PermissionDialogContent({
    required this.explanation,
    required this.theme,
    required this.primaryLabel,
    required this.primaryAction,
    required this.secondaryLabel,
    required this.secondaryAction,
    super.key,
  });

  final PermissionExplanation explanation;
  final PermissionTheme theme;
  final String primaryLabel;
  final VoidCallback primaryAction;
  final String secondaryLabel;
  final VoidCallback secondaryAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Icon(
            explanation.icon,
            size: theme.iconSize,
            color: colors.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          explanation.title,
          style: typography.titleMedium.copyWith(color: colors.onSurface),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          explanation.description,
          style: typography.bodyMedium.copyWith(
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        AppButton(
          label: primaryLabel,
          onPressed: primaryAction,
        ),
        const SizedBox(height: 8),
        AppButton(
          label: secondaryLabel,
          onPressed: secondaryAction,
          type: AppButtonType.outline,
        ),
      ],
    );
  }
}
