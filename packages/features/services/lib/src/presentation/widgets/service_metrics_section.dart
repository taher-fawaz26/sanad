import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:services/src/presentation/bloc/service_analytics/service_analytics_bloc.dart';

/// Dashboard KPI cards — Figma `4715:26122`.
///
/// Backed by `GET /services/analytics`. The live backend always reports
/// `dataAvailable: false` today (booking entity not implemented yet), so
/// this renders an explicit "not available yet" placeholder rather than the
/// zeroed metrics whenever that flag is false.
class ServiceMetricsSection extends StatelessWidget {
  const ServiceMetricsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ServiceAnalyticsBloc, ServiceAnalyticsState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const ShimmerListSkeleton();
        }
        if (!state.hasAvailableData) {
          return _AnalyticsUnavailableCard();
        }

        final analytics = state.analytics!;
        return _MetricsGrid(
          orders: analytics.overall.totalRequests.toString(),
          revenue: analytics.overall.totalRevenue.toString(),
          completionRate: '${analytics.completion.completionRate}%',
          cancelledPercent: analytics.completion.cancelledCount.toString(),
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
    required this.revenue,
    required this.completionRate,
    required this.cancelledPercent,
  });

  final String orders;
  final String revenue;
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
          child: Row(
            children: [
              Expanded(
                child: _MetricCard(
                  label: 'services.metric_orders'.tr(),
                  child: Text(
                    orders,
                    style: typography
                        .medium(typography.title3)
                        .copyWith(
                          color: colors.textPrimary,
                          letterSpacing: -0.48,
                        ),
                  ),
                ),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: _MetricCard(
                  label: 'services.metric_revenue'.tr(),
                  child: Text(
                    '$revenue ${'services.currency_aed'.tr()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
