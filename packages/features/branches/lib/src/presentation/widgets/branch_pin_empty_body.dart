import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Centered 40dp icon + title + description (Figma `1563:10978` /
/// `1563:10992` / `1563:10998`) — shared by the add-branch coverage,
/// location-permission-denied, and services empty states.
class BranchPinEmptyBody extends StatelessWidget {
  const BranchPinEmptyBody({
    required this.title,
    required this.description,
    this.icon,
    super.key,
  });

  final String title;
  final String description;

  /// Custom 40dp icon; defaults to the outline map pin.
  final Widget? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final pinSize = responsiveDimension(40);

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                AppSvgPicture.asset(
                  AppSvgs.pin,
                  width: pinSize,
                  height: pinSize,
                ),
            SizedBox(height: AppSpacing.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography
                  .semiBold(typography.regularNormal)
                  .copyWith(
                    color: colors.textPrimary,
                  ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              description,
              textAlign: TextAlign.center,
              style: typography.smallNormal.copyWith(
                color: colors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
