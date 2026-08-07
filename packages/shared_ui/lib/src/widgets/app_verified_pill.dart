import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma verified header pill (`3821:19111` / `3821:19106`).
///
/// Solid primary pill with label and trailing checkmark disc. View-only.
class AppVerifiedPill extends StatelessWidget {
  const AppVerifiedPill({
    super.key,
    this.label = 'Verified',
  });

  final String label;

  static const double _iconDiscSize = 16;
  static const double _checkIconSize = 10;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(AppDimension.radiusPill),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: typography.regularNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.onPrimary,
              ),
            ),
            SizedBox(width: AppSpacing.sm),
            DecoratedBox(
              decoration: BoxDecoration(
                color: colors.onPrimary,
                shape: BoxShape.circle,
              ),
              child: SizedBox(
                width: _iconDiscSize,
                height: _iconDiscSize,
                child: Icon(
                  Icons.check,
                  size: _checkIconSize,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
