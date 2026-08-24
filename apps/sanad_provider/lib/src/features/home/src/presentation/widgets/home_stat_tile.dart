import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One dashboard statistic tile — icon badge, value, label.
///
/// Visual language matches [AppStatCard]'s KPI-card tokens (white surface,
/// bordered, 48dp icon circle) but lays out vertically for a grid, with no
/// action button.
class HomeStatTile extends StatelessWidget {
  const HomeStatTile({
    required this.icon,
    required this.iconBackgroundColor,
    required this.value,
    required this.label,
    this.onTap,
    super.key,
  });

  final Widget icon;
  final Color iconBackgroundColor;
  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(responsiveDimension(16)),
      child: Container(
        padding: EdgeInsets.all(responsiveSpacing(16)),
        decoration: BoxDecoration(
          color: colors.white,
          borderRadius: BorderRadius.circular(responsiveDimension(16)),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: responsiveDimension(40),
              height: responsiveDimension(40),
              decoration: BoxDecoration(
                color: iconBackgroundColor,
                borderRadius: BorderRadius.circular(responsiveDimension(10)),
              ),
              alignment: Alignment.center,
              child: icon,
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              value,
              style: typography.regularNormal.copyWith(
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: typography.smallNormal.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
