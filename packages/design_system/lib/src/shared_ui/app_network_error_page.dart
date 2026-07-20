import 'package:app_assets/app_assets.dart';
import 'package:design_system/src/components/app_button.dart';
import 'package:design_system/src/components/app_feature_icon.dart';
import 'package:design_system/src/components/app_nav_bar.dart';
import 'package:design_system/src/spacing/responsive_spacing.dart';
import 'package:design_system/src/theme/colors/app_colors.dart';
import 'package:design_system/src/theme/tokens/feature_icon_tokens.dart';
import 'package:design_system/src/theme/typography/app_typography.dart';
import 'package:flutter/material.dart';

/// Full-screen network error — Figma `Screen 4: Network Error` (`1528:10165`).
///
/// Layout: nav bar (back + optional title) → centered featured internet icon
/// + copy → bottom Retry. Push this route so the user can pop back and open
/// it again later.
class AppNetworkErrorPage extends StatelessWidget {
  const AppNetworkErrorPage({
    required this.title,
    required this.description,
    required this.retryLabel,
    super.key,
    this.navTitle = '',
    this.onRetry,
    this.onBack,
  });

  /// Optional previous-screen title shown in the nav bar (e.g. "Team").
  final String navTitle;

  final String title;
  final String description;
  final String retryLabel;
  final VoidCallback? onRetry;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavBar(
              title: navTitle,
              showBackButton: true,
              onLeadingTap: onBack,
            ),
            Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppFeatureIcon(
                        color: AppFeatureIconColor.gray,
                        size: AppFeatureIconSize.lg,
                        iconAsset: AppSvgs.internet,
                      ),
                      SizedBox(height: AppSpacing.xxl),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: typography.title3.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 32 / 24,
                          color: colors.textPrimary,
                        ),
                      ),
                      SizedBox(height: AppSpacing.sm),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: typography.regularNormal.copyWith(
                          height: 24 / 16,
                          color: colors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.sm,
              ),
              child: AppButton(
                label: retryLabel,
                onPressed: onRetry,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
