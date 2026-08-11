import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:services/src/presentation/models/provider_service_card_data.dart';

/// Visual service card — Figma `Service-Card-Visual` (`4715:26250`).
class ServiceProviderCard extends StatelessWidget {
  const ServiceProviderCard({
    required this.data,
    super.key,
    this.onTap,
    this.onMoreTap,
  });

  final ProviderServiceCardData data;
  final VoidCallback? onTap;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final coverHeight = responsiveDimension(116);

    final radius = BorderRadius.circular(AppDimension.radiusMd);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: radius,
        border: Border.all(color: colors.palettes.sky.shade200),
        boxShadow: AppShadows.xs,
      ),
      child: Material(
        color: colors.surface.withValues(alpha: 0),
        borderRadius: radius,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: coverHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    ColoredBox(color: colors.palettes.sky.shade100),
                    if (data.coverImageUrl != null)
                      AppNetworkImage(
                        data.coverImageUrl!,
                        fit: BoxFit.cover,
                      ),
                    if (data.showMoreAction)
                      PositionedDirectional(
                        top: AppSpacing.md,
                        end: AppSpacing.md,
                        child: _MoreButton(onTap: onMoreTap),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            data.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: typography
                                .bold(typography.largeTight)
                                .copyWith(color: colors.textPrimary),
                          ),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        AppStatusBadge(
                          label: data.statusLabel,
                          type: data.isActive
                              ? AppStatusBadgeType.success
                              : AppStatusBadgeType.warning,
                          size: AppStatusBadgeSize.dense,
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.md),
                    AppChip(
                      label: data.category,
                      tone: AppChipTone.softNeutral,
                    ),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      data.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: typography.smallNormal.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.palettes.sky.shade200,
                    ),
                    SizedBox(height: AppSpacing.md),
                    _StatsRow(
                      requestsCount: data.requestsCount,
                      revenueLabel: data.revenueLabel,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreButton extends StatelessWidget {
  const _MoreButton({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = responsiveDimension(32);

    return Material(
      color: context.appColors.palettes.dark.shade950.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(size / 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(
            Icons.more_vert,
            size: AppDimension.iconSm,
            color: context.appColors.surface,
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.requestsCount,
    required this.revenueLabel,
  });

  final String requestsCount;
  final String revenueLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatItem(
            iconAsset: AppSvgs.fileText,
            label: 'services.card_requests'.tr(),
            value: requestsCount,
          ),
        ),
        Container(
          width: 1,
          height: responsiveDimension(56),
          color: context.appColors.palettes.sky.shade200,
        ),
        Expanded(
          child: _StatItem(
            iconAsset: AppSvgs.wallet,
            label: 'services.card_revenue'.tr(),
            value: revenueLabel,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.iconAsset,
    required this.label,
    required this.value,
  });

  final String iconAsset;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final iconBox = responsiveDimension(40);
    final iconSize = responsiveDimension(18);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: iconBox,
          height: iconBox,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.palettes.sky.shade50,
            borderRadius: BorderRadius.circular(iconBox / 2),
          ),
          child: AppSvgPicture.asset(
            iconAsset,
            width: iconSize,
            height: iconSize,
            colorFilter: ColorFilter.mode(
              colors.textPrimary,
              BlendMode.srcIn,
            ),
          ),
        ),
        SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Column(
            children: [
              Text(
                label,
                textAlign: TextAlign.center,
                style: typography.tinyNormal.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              SizedBox(height: responsiveSpacing(6)),
              Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: typography
                    .semiBold(typography.smallTight)
                    .copyWith(
                      color: colors.primary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
