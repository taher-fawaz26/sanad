import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:services/src/domain/entities/catalog_service_selection.dart';

/// Bordered service row — Figma add-branch `Service Card` (`962:6343`).
///
/// Layout: `[48dp icon container] [Name + Category] [trash]`.
class ServiceListCard extends StatelessWidget {
  const ServiceListCard({
    required this.service,
    super.key,
    this.onTap,
    this.onRemove,
  });

  final CatalogServiceSelection service;
  final VoidCallback? onTap;

  /// Shows a trailing trash button when provided.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final sky = colors.palettes.sky;
    final iconBoxSize = responsiveDimension(48);
    final iconSize = AppDimension.iconMenu;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: responsiveDimension(80),
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimension.radiusMd),
          border: Border.all(color: sky.shade300),
        ),
        child: Row(
          children: [
            Container(
              width: iconBoxSize,
              height: iconBoxSize,
              decoration: BoxDecoration(
                color: sky.shade100,
                borderRadius: BorderRadius.circular(AppDimension.radiusSm),
              ),
              alignment: Alignment.center,
              child: AppSvgPicture.asset(
                AppSvgs.car,
                width: iconSize,
                height: iconSize,
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography
                        .medium(typography.regularTight)
                        .copyWith(
                          color: colors.textPrimary,
                        ),
                  ),
                  SizedBox(height: responsiveDimension(2)),
                  Text(
                    service.categoryName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typography.smallTight.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (onRemove != null) ...[
              SizedBox(width: AppSpacing.md),
              GestureDetector(
                onTap: onRemove,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  child: AppSvgPicture.asset(
                    AppSvgs.trash,
                    width: AppDimension.iconMd,
                    height: AppDimension.iconMd,
                    colorFilter: ColorFilter.mode(
                      colors.error,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
