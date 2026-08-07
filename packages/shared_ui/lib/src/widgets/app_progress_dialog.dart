import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// Figma loading-state dialog (`1546:8536`).
///
/// Centered card with [AppLoadingIndicator], title, and optional description.
/// Prefer [showAppProgressDialog] for the full modal experience.
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

/// Shows a non-dismissible progress dialog (Figma `1546:8536`).
///
/// Use for long-running create/edit flows (invite worker, add branch, etc.).
/// Dismiss with [dismissAppProgressDialog] when the request finishes.
Future<void> showAppProgressDialog({
  required BuildContext context,
  required String title,
  String? description,
}) {
  final barrierColor = context.appDialogTheme.spec.barrierColor;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: barrierColor,
    builder: (dialogContext) {
      return PopScope(
        canPop: false,
        child: AppProgressDialog(
          title: title,
          description: description,
        ),
      );
    },
  );
}

/// Pops the top-most [showAppProgressDialog] via the root navigator.
void dismissAppProgressDialog(BuildContext context) {
  final navigator = Navigator.of(context, rootNavigator: true);
  if (navigator.canPop()) {
    navigator.pop();
  }
}
