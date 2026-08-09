import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Figma services empty state (`4715:23588`).
class ServicesEmptyState extends StatelessWidget {
  const ServicesEmptyState({super.key, this.onAddService});

  final VoidCallback? onAddService;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final iconSize = responsiveDimension(32);
    final contentWidth = EmptyStateTokens.resolve(
      colors: colors,
      typography: typography,
    ).contentWidth;

    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppSvgPicture.asset(
              AppSvgs.tools,
              width: iconSize,
              height: iconSize,
              colorFilter: ColorFilter.mode(
                colors.textMuted,
                BlendMode.srcIn,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: contentWidth,
              child: Column(
                children: [
                  Text(
                    'services.empty_title'.tr(),
                    textAlign: TextAlign.center,
                    style: typography
                        .semiBold(typography.regularNormal)
                        .copyWith(color: colors.textPrimary),
                  ),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'services.empty_description'.tr(),
                    textAlign: TextAlign.center,
                    style: typography.smallNormal.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onAddService != null) ...[
              SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: contentWidth,
                child: AppButton(
                  label: 'services.add_first_service'.tr(),
                  onPressed: onAddService,
                  icon: Icon(
                    Icons.add,
                    size: AppDimension.iconMd,
                    color: colors.onPrimary,
                  ),
                  iconPosition: AppButtonIconPosition.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Empty state for the Service request tab.
class ServiceRequestsEmptyState extends StatelessWidget {
  const ServiceRequestsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final iconSize = responsiveDimension(48);

    return AppEmptyState(
      illustration: AppSvgPicture.asset(
        AppSvgs.fileText,
        width: iconSize,
        height: iconSize,
        colorFilter: ColorFilter.mode(
          context.appColors.textMuted,
          BlendMode.srcIn,
        ),
      ),
      title: 'services.requests_empty_title'.tr(),
      description: 'services.requests_empty_description'.tr(),
    );
  }
}
