import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:flutter/material.dart';

/// Sticky footer bar for wizard and review screens (Figma bottom CTA rows).
class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    required this.child,
    super.key,
    this.padding,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding:
            padding ??
            EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.sm,
            ),
        child: child,
      ),
    );
  }
}
