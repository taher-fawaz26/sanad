import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// One dashboard statistic tile — Figma `6755:25961`.
///
/// Layout: a header row with the label on the leading edge and a tinted
/// icon badge on the trailing edge, then the value below. Compact (~96dp)
/// to match the Figma metric card, distinct from [AppStatCard]'s KPI layout.
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

    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimension.radiusMd),
        side: BorderSide(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(responsiveSpacing(14)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: typography.tinyNormal.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Container(
                    width: responsiveDimension(32),
                    height: responsiveDimension(32),
                    decoration: BoxDecoration(
                      color: iconBackgroundColor,
                      borderRadius: BorderRadius.circular(
                        AppDimension.radiusSm,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: icon,
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.sm),
              Text(
                value,
                style: typography.title3.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
