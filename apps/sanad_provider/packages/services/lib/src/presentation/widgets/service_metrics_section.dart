import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';
import 'package:shared_ui/shared_ui.dart';

/// Dashboard KPI cards — Figma `4715:26122`.
///
/// Backed by `GET /provider-services/overview`. The live backend always
/// reports `dataAvailable: false` today, so this renders an explicit "not
/// available yet" placeholder rather than the stub zeros whenever that flag
/// is false. There is no price/revenue on the new contract.
class ServiceMetricsSection extends StatelessWidget {
  const ServiceMetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceAnalyticsBloc, ServiceAnalyticsState>(
      builder: (context, state) {
        if (state.isLoading) {
          // Skeletonize the *real* metrics grid with placeholder values
          // instead of a bespoke skeleton layout.
          return AppSkeletonizer(
            enabled: true,
            child: _MetricsGrid(
              orders: BoneMock.chars(3),
              completionRate: '${BoneMock.chars(2)}%',
              cancelledPercent: BoneMock.chars(2),
            ),
          );
        }
        if (!state.hasAvailableData) {
          return _AnalyticsUnavailableCard();
        }

        final overview = state.overview!;
        return _MetricsGrid(
          orders: overview.totalRequests.toString(),
          completionRate: '${overview.completionRate}%',
          cancelledPercent: overview.cancelledCount.toString(),
        );
      },
    );
  }
}

class _AnalyticsUnavailableCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: colors.palettes.sky.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'services.metrics_unavailable_title'.tr(),
            style: typography
                .semiBold(typography.regularNormal)
                .copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            'services.metrics_unavailable_description'.tr(),
            style: typography.smallNormal.copyWith(color: colors.textMuted),
          ),
        ],
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({
    required this.orders,
    required this.completionRate,
    required this.cancelledPercent,
  });

  final String orders;
  final String completionRate;
  final String cancelledPercent;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final cardHeight = responsiveDimension(100);

    return Column(
      children: [
        SizedBox(
          height: cardHeight,
          child: _MetricCard(
            label: 'services.metric_orders'.tr(),
            child: Text(
              orders,
              style: typography
                  .medium(typography.title3)
                  .copyWith(color: colors.textPrimary, letterSpacing: -0.48),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.md),
        SizedBox(
          height: cardHeight,
          child: _MetricCard(
            label: 'services.metric_completion_rate'.tr(),
            labelStyle: typography
                .medium(typography.smallNormal)
                .copyWith(color: colors.textPrimary),
            trailing: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: responsiveSpacing(2),
              ),
              decoration: BoxDecoration(
                color: colors.errorContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Text(
                'services.metric_cancelled'.tr(
                  namedArgs: {'percent': cancelledPercent},
                ),
                style: typography
                    .semiBold(typography.smallTight)
                    .copyWith(
                      color: colors.error,
                    ),
              ),
            ),
            child: Text(
              completionRate,
              style: typography
                  .medium(typography.title3)
                  .copyWith(
                    color: colors.textPrimary,
                    letterSpacing: -0.48,
                  ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.child,
    this.labelStyle,
    this.trailing,
  });

  final String label;
  final Widget child;
  final TextStyle? labelStyle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final sky = colors.palettes.sky;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        border: Border.all(color: sky.shade200),
      ),
      child: trailing == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style:
                      labelStyle ??
                      typography
                          .semiBold(typography.regularNormal)
                          .copyWith(color: colors.textPrimary),
                ),
                SizedBox(height: AppSpacing.sm),
                child,
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        label,
                        style:
                            labelStyle ??
                            typography
                                .medium(typography.smallNormal)
                                .copyWith(color: colors.textPrimary),
                      ),
                      child,
                    ],
                  ),
                ),
                trailing!,
              ],
            ),
    );
  }
}
