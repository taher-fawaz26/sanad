import 'package:design_system/src/components/app_svg_picture.dart';
import 'package:design_system/src/dimensions/responsive_dimension.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Compact illustrated empty state for bottom sheets and inline panels.
///
/// Figma sheet search empty (`1517:9679`, `1517:9708`).
class AppIllustratedEmptyState extends StatelessWidget {
  const AppIllustratedEmptyState({
    required this.iconAsset,
    required this.title,
    required this.description,
    super.key,
    this.iconSize = 48,
  });

  final String iconAsset;
  final String title;
  final String description;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final size = responsiveDimension(iconSize);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppSvgPicture.asset(
            iconAsset,
            width: size,
            height: size,
          ),
          SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: typography.regularNormal.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            description,
            style: typography.smallNormal.copyWith(
              color: colors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
