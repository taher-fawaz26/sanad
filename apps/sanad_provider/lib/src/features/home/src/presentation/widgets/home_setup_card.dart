import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:sanad_provider/src/features/organization_settings/organization_settings.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home "Setup Progress" card — Figma `6755:25950`.
///
/// Deliberately the slim Home variant of Organization Settings' setup hub:
/// overall percentage + progress bar + a single "Complete Setup" CTA — no
/// per-stage breakdown (that detail stays in Organization Settings). Reuses
/// the same [ProviderCompletionBloc] data source; no duplicated business
/// logic or a second backend call model.
class HomeSetupCard extends StatelessWidget {
  const HomeSetupCard({required this.onCompleteSetup, super.key});

  final VoidCallback onCompleteSetup;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProviderCompletionBloc, ProviderCompletionState>(
      builder: (context, state) {
        if (state.hasError && state.completion == null) {
          return _SetupCardError(
            failure: state.failure,
            onRetry: () => context.read<ProviderCompletionBloc>().add(
              const ProviderCompletionRefreshed(),
            ),
          );
        }

        final isLoading =
            state.status == RequestStatus.initial ||
            (state.isLoading && state.completion == null);

        return AppSkeletonizer(
          enabled: isLoading,
          child: _SetupCardContent(
            completion: state.completion ?? _skeletonCompletion,
            onCompleteSetup: onCompleteSetup,
          ),
        );
      },
    );
  }
}

const ProviderCompletionEntity _skeletonCompletion = ProviderCompletionEntity(
  percentage: 0,
  requiredCompleted: 0,
  requiredTotal: 0,
  visibleToCustomers: true,
  items: <ProviderCompletionItemEntity>[],
);

class _SetupCardContent extends StatelessWidget {
  const _SetupCardContent({
    required this.completion,
    required this.onCompleteSetup,
  });

  final ProviderCompletionEntity completion;
  final VoidCallback onCompleteSetup;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpacing.md,
        children: [
          Row(
            spacing: AppSpacing.sm,
            children: [
              Expanded(
                child: Text(
                  'home.setup_title'.tr(
                    namedArgs: {
                      'percent': completion.percentage.round().toString(),
                    },
                  ),
                  style: typography.regularNormal.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  'home.setup_steps_summary'.tr(
                    namedArgs: {
                      'completed': completion.requiredCompleted.toString(),
                      'total': completion.requiredTotal.toString(),
                    },
                  ),
                  style: typography.smallNormal.copyWith(
                    color: colors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          AppProgressBar(value: completion.percentage / 100),
          AppButton(
            label: 'home.complete_setup'.tr(),
            variant: AppButtonVariant.outline,
            onPressed: onCompleteSetup,
          ),
        ],
      ),
    );
  }
}

class _SetupCardError extends StatelessWidget {
  const _SetupCardError({required this.onRetry, this.failure});

  final Failure? failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final display = failureErrorDisplay(failure);
    return AppErrorState(
      style: display.isConnectivity
          ? AppErrorStateStyle.network
          : AppErrorStateStyle.generic,
      title: display.title,
      description: display.description,
      retryLabel: failureRetryLabel(),
      onRetry: display.isRetryable ? onRetry : null,
    );
  }
}
