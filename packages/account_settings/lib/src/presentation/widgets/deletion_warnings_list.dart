import 'package:account_settings/src/domain/entities/deletion_warning.dart';
import 'package:account_settings/src/presentation/mappers/deletion_code_localizer.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

/// Renders every non-blocking warning the account should confirm before
/// deleting, as a single red-bordered "permanently erased" panel with a
/// bulleted list (Figma delete-account screen). Never truncated.
class DeletionWarningsList extends StatelessWidget {
  const DeletionWarningsList({required this.warnings, super.key});

  final List<DeletionWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.error),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'account_deletion.permanent_erase_title'.tr(),
            style: typography.regularNormal.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.error,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          for (var i = 0; i < warnings.length; i++) ...[
            if (i > 0) SizedBox(height: AppSpacing.xs),
            _WarningBullet(text: warnings[i].localizedMessage()),
          ],
        ],
      ),
    );
  }
}

class _WarningBullet extends StatelessWidget {
  const _WarningBullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsetsDirectional.only(
            top: AppSpacing.xs,
            end: AppSpacing.sm,
          ),
          child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: colors.error,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: typography.smallNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}
