import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// "Enhance with AI" pill — Figma's `Main` instance floating over the
/// description field on both the Add Service (`5261:44387`) and Request New
/// Service (`4715:24468`) forms. UI-only per this pass: no AI backend
/// exists, so this is intentionally a no-op placeholder (see audit
/// blockers) rather than a fabricated integration.
class AddServiceAiEnhanceButton extends StatelessWidget {
  const AddServiceAiEnhanceButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusPill),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.auto_awesome,
              size: AppDimension.iconSm,
              color: colors.primary,
            ),
            SizedBox(width: AppSpacing.xs),
            Text(
              'services.add_service.ai_enhance'.tr(),
              style: typography.smallNormal.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
