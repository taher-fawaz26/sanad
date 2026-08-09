import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Dashboard KPI cards — Figma `4715:26122`.
class ServiceMetricsSection extends StatelessWidget {
  const ServiceMetricsSection({
    super.key,
    this.orders = '2,420',
    this.revenue = '58,230',
    this.completionRate = '87%',
    this.cancelledPercent = '13',
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
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          revenue,
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
                      SizedBox(width: AppSpacing.xs),
                      Image.asset(
                        AppImages.dirham,
                        package: AppAssets.package,
                        width: responsiveDimension(28),
                        height: responsiveDimension(24),
                      ),
                    ],
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
