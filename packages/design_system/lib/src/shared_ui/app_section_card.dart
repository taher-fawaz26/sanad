import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Card surface for a titled content section with an optional edit action.
///
/// Domain-agnostic wrapper used across settings and other feature screens.
class AppSectionCard extends StatelessWidget {
  /// Creates a section card.
  const AppSectionCard({
    required this.child,
    super.key,
    this.title,
    this.subtitle,
    this.onEdit,
  });

  /// Section body content.
  final Widget child;

  /// Optional header title.
  final String? title;

  /// Optional header subtitle.
  final String? subtitle;

  /// Optional edit callback shown in the header.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasHeader = title != null || subtitle != null || onEdit != null;

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
          if (hasHeader)
            AppSectionHeader(
              title: title,
              subtitle: subtitle,
              onEdit: onEdit,
            ),
          child,
        ],
      ),
    );
  }
}
