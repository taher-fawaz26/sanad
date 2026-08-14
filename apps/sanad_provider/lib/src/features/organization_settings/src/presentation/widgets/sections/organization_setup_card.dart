import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sanad_provider/src/features/organization_settings/src/domain/entities/provider_completion_entity.dart';
import 'package:sanad_provider/src/features/organization_settings/src/presentation/widgets/sections/organization_setup_stages.dart';

/// Card drop shadow — Figma effect style on `organization-setup-stepper`
/// (`4349:5171`), not part of [AppShadows]' ink-based scale.
const _kCardShadow = BoxShadow(
  color: Color(0x0D101828),
  blurRadius: 9,
  offset: Offset(0, 6),
);

/// Unbound gray from Figma's raw fill (not tied to a Figma variable) —
/// closest border for the small unchecked-stage badge ring.
const _kUncheckedBadgeBorder = Color(0xFFCDCFD0);

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
    final nextUpIndex = stages.indexWhere((stage) => !stage.completed);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border.all(color: colors.border),
        borderRadius: BorderRadius.circular(AppDimension.radiusProfileCard),
        boxShadow: const [_kCardShadow],
      ),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xl,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 6,
              children: [
                Text(
                  'settings.setup_title'.tr(),
                  style: typography.largeNormal.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'settings.setup_description'.tr(),
                  style: typography.tinyNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
            if (!completion.visibleToCustomers)
              const _HiddenFromCustomersBadge(),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: AppSpacing.lg,
              children: [
                for (var i = 0; i < stages.length; i++) ...[
                  if (i > 0) const _StageConnector(),
                  _StageRow(
                    stage: stages[i],
                    isNextUp: i == nextUpIndex,
                    onAdd: () => onStageAction(stages[i].id),
                  ),
                ],
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: AppSpacing.md,
                  children: [
                    Expanded(
                      child: Text(
                        'settings.setup_required_summary'.tr(
                          namedArgs: {
                            'completed': completion.requiredCompleted
                                .toString(),
                            'total': completion.requiredTotal.toString(),
                          },
                        ),
                        style: typography.smallNormal.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Text(
                      '${completion.percentage.round()}%',
                      style: typography.smallNormal.copyWith(
                        color: colors.onSuccessContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                AppProgressBar(value: completion.percentage / 100),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.stage,
    required this.isNextUp,
    required this.onAdd,
  });

  final OrganizationSetupStage stage;

  /// Whether this is the first incomplete stage — Figma dims stages beyond
  /// it a step further (`sky/300` subtitle vs `sky/400`).
  final bool isNextUp;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final sky = colors.palettes.sky;

    final titleColor = stage.completed ? colors.textPrimary : sky.shade400;
    final subtitleColor = stage.completed
        ? colors.textMuted
        : (isNextUp ? sky.shade400 : sky.shade300);

    return Row(
      spacing: AppSpacing.lg,
      children: [
        _StageIcon(stage: stage),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 4,
            children: [
              Text(
                stage.titleKey.tr(),
                style: typography.smallNormal.copyWith(
                  color: titleColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                stage.subtitleKey.tr(),
                style: typography.tinyNormal.copyWith(color: subtitleColor),
              ),
            ],
          ),
        ),
        if (!stage.completed)
          GestureDetector(
            onTap: onAdd,
            child: Text(
              'common.add'.tr(),
              style: typography.smallNormal.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w500,
                decoration: TextDecoration.underline,
                decorationColor: colors.primary,
              ),
            ),
          ),
      ],
    );
  }
}

class _StageIcon extends StatelessWidget {
  const _StageIcon({required this.stage});

  final OrganizationSetupStage stage;

  static const double _containerSize = 40;
  static const double _circleSize = 38;
  static const double _glyphSize = 19;
  static const double _badgeSize = 11;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final completed = stage.completed;

    return SizedBox(
      width: _containerSize,
      height: _containerSize,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: Container(
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                color: completed
                    ? colors.palettes.accent.shade50
                    : colors.palettes.dark.shade50,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: AppSvgPicture.asset(
                stage.iconAsset,
                width: _glyphSize,
                height: _glyphSize,
                colorFilter: ColorFilter.mode(
                  completed ? colors.textPrimary : colors.textMuted,
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: completed
                ? Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Icon(Icons.check, size: 7, color: colors.onPrimary),
                  )
                : Container(
                    width: _badgeSize,
                    height: _badgeSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _kUncheckedBadgeBorder),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/// Hairline between stage rows — Figma `Connector` (`sky/200`), distinct
/// from [AppDivider]'s `dark` ramp default.
class _StageConnector extends StatelessWidget {
  const _StageConnector();

  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: context.appColors.palettes.sky.shade200);
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
        color: colors.palettes.red.shade50,
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
                color: colors.palettes.red.shade500,
                shape: BoxShape.circle,
              ),
            ),
            Flexible(
              child: Text(
                'settings.setup_hidden_badge'.tr(),
                style: typography.smallNormal.copyWith(
                  color: colors.palettes.red.shade500,
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
