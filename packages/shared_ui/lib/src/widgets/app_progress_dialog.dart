import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma loading-state dialog (`1546:8536`).
///
/// Centered card with [AppLoadingIndicator], title, and optional description.
/// Prefer driving this through `AppProgress`/`MutationListener`
/// (`shared_ui/src/loading/`) rather than showing it directly.
class AppProgressDialog extends StatelessWidget {
  const AppProgressDialog({
    required this.title,
    super.key,
    this.description,
  });

  final String title;
  final String? description;

  /// Spinner diameter — Figma loader frame ≈ 80 dp (`1526:12561`).
  static const double indicatorSize = 80;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final padding = responsiveDimension(
      DialogTokens.contentPaddingTopWithImage,
    );
    final gap = AppSpacing.xxl;
    final textGap = AppSpacing.sm;

    return Dialog(
      backgroundColor: colors.surface,
      elevation: 0,
      insetPadding: EdgeInsets.symmetric(
        horizontal: context.appDialogTheme.spec.horizontalInset,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: context.appDialogTheme.spec.borderRadius,
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppLoadingIndicator(
              size: responsiveDimension(indicatorSize),
            ),
            SizedBox(height: gap),
            Text(
              title,
              textAlign: TextAlign.center,
              style: typography.title3.copyWith(
                fontWeight: FontWeight.w700,
                height: 32 / 24,
                color: colors.textPrimary,
              ),
            ),
            if (description != null && description!.trim().isNotEmpty) ...[
              SizedBox(height: textGap),
              Text(
                description!,
                textAlign: TextAlign.center,
                style: typography.regularNormal.copyWith(
                  height: 24 / 16,
                  color: colors.textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
