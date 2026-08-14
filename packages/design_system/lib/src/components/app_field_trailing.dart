import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Figma inline field trailing actions (`3784:17518`, `3784:17463`).
sealed class AppFieldTrailing {
  const AppFieldTrailing();
}

/// Small outline pill with optional leading icon — Figma `3784:17518`.
class AppFieldOutlinePillTrailing extends AppFieldTrailing {
  const AppFieldOutlinePillTrailing({
    required this.label,
    this.onTap,
    this.icon = Icons.add,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData icon;
}

/// Underlined primary text action — Figma `3784:17463`.
class AppFieldTextLinkTrailing extends AppFieldTrailing {
  const AppFieldTextLinkTrailing({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;
}

/// Renders an [AppFieldTrailing] for use inside field suffix slots.
class AppFieldTrailingView extends StatelessWidget {
  const AppFieldTrailingView({
    required this.trailing,
    super.key,
    this.enabled = true,
  });

  final AppFieldTrailing trailing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return switch (trailing) {
      AppFieldOutlinePillTrailing(:final label, :final onTap, :final icon) =>
        _OutlinePill(
          label: label,
          icon: icon,
          onTap: enabled ? onTap : null,
        ),
      AppFieldTextLinkTrailing(:final label, :final onTap) => _TextLink(
        label: label,
        onTap: enabled ? onTap : null,
      ),
    };
  }
}

class _OutlinePill extends StatelessWidget {
  const _OutlinePill({
    required this.label,
    required this.icon,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimension.radiusPill),
        child: Ink(
          height: responsiveDimension(24),
          padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimension.radiusPill),
            border: Border.all(color: colors.primary),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: colors.primary),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: typography.smallNormal.copyWith(
                  fontSize: 12,
                  height: 16 / 12,
                  fontWeight: FontWeight.w500,
                  color: colors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TextLink extends StatelessWidget {
  const _TextLink({
    required this.label,
    this.onTap,
  });

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: typography.smallNormal.copyWith(
          fontSize: 12,
          height: 16 / 12,
          fontWeight: FontWeight.w500,
          color: colors.primary,
          decoration: TextDecoration.underline,
          decorationColor: colors.primary,
        ),
      ),
    );
  }
}
