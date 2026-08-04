import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_edit_button.dart';

/// Card wrapper for a general settings view-mode section.
class SettingsSectionCard extends StatelessWidget {
  const SettingsSectionCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.onEdit,
  });

  final Widget child;
  final VoidCallback? onEdit;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: ShapeDecoration(
        color: colors.background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSpacing.lg,
        children: [
          SettingsEditButton(
            title: title,
            subtitle: subtitle,
            onEdit: onEdit,
            colors: colors,
            typography: typography,
          ),
          child,
        ],
      ),
    );
  }
}
