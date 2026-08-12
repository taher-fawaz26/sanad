import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_stages.dart';

/// "Complete your organization setup" card — Figma `4349-5171`.
///
/// Pure presentation: every value comes from [completion]
/// (`GET service-provider/completion`) — this widget owns no bloc and makes
/// no API calls. The progress bar/summary always uses the backend's
/// [ProviderCompletionEntity.percentage]/`requiredCompleted`/`requiredTotal` —
/// never a locally-computed stage count.
class OrganizationSetupCard extends StatelessWidget {
  const OrganizationSetupCard({
    required this.completion,
    required this.onStageAction,
    super.key,
  });

  final ProviderCompletionEntity completion;

  /// Invoked when the user taps "Add" on an incomplete stage.
  final ValueChanged<OrganizationSetupStageId> onStageAction;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final stages = mapCompletionToStages(completion);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppDimension.radiusLg),
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.lg,
          children: [
            Text(
              'settings.setup_title'.tr(),
              style: typography.title3.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              'settings.setup_description'.tr(),
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
              ),
            ),
            if (!completion.visibleToCustomers)
              const _HiddenFromCustomersBadge(),
            const AppDivider(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.md,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const AppDivider(),
                  _StageRow(
                    stage: stages[i],
                    onAdd: () => onStageAction(stages[i].id),
                  ),
                ],
              ],
            ),
            Text(
              'settings.setup_required_summary'.tr(
                namedArgs: {
                  'completed': completion.requiredCompleted.toString(),
                  'total': completion.requiredTotal.toString(),
                },
              ),
              style: typography.smallNormal.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              spacing: AppSpacing.md,
              children: [
                Expanded(
                  child: AppProgressBar(value: completion.percentage / 100),
                ),
                Text(
                  '${completion.percentage.round()}%',
                  style: typography.smallNormal.copyWith(
                    color: colors.success,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({required this.stage, required this.onAdd});

  final OrganizationSetupStage stage;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Row(
      spacing: AppSpacing.md,
      children: [
        _StageStatusIcon(completed: stage.completed),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                stage.titleKey.tr(),
                style: typography.regularNormal.copyWith(
                  color: stage.completed
                      ? colors.textPrimary
                      : colors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                stage.subtitleKey.tr(),
                style: typography.smallNormal.copyWith(
                  color: colors.textMuted,
                ),
              ),
            ],
          ),
        ),
        if (!stage.completed)
          GestureDetector(
            onTap: onAdd,
            child: Text(
              'settings.add'.tr(),
              style: typography.regularNormal.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

class _StageStatusIcon extends StatelessWidget {
  const _StageStatusIcon({required this.completed});

  final bool completed;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (completed) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.successContainer,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(Icons.check, size: 18, color: colors.onSuccessContainer),
      );
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: colors.palettes.dark.shade50,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(Icons.person_outline, size: 18, color: colors.textMuted),
    );
  }
}

class _HiddenFromCustomersBadge extends StatelessWidget {
  const _HiddenFromCustomersBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(AppDimension.radiusSm),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.sm,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.onErrorContainer,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(
                'settings.setup_hidden_badge'.tr(),
                style: typography.smallNormal.copyWith(
                  color: colors.onErrorContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
