import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

/// Figma error-state dialog (`1546:8473`).
///
/// Styled to match [AppProgressDialog] but with an error icon and a retry
/// button instead of a spinner.
class _ProfileCompletionErrorDialog extends StatelessWidget {
  const _ProfileCompletionErrorDialog({this.errorMessage});

  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final padding = responsiveDimension(
      DialogTokens.contentPaddingTopWithImage,
    );

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
            AppSvgPicture.asset(
              AppSvgs.alertCircle,
              width: responsiveDimension(80),
              height: responsiveDimension(80),
            ),
            SizedBox(height: AppSpacing.xxl),
            Text(
              'registration.profile_complete_error_title'.tr(),
              textAlign: TextAlign.center,
              style: typography.title3.copyWith(
                fontWeight: FontWeight.w700,
                height: 32 / 24,
                color: colors.textPrimary,
              ),
            ),
            SizedBox(height: AppSpacing.sm),
            Text(
              errorMessage ??
                  'registration.profile_complete_error_message'.tr(),
              textAlign: TextAlign.center,
              style: typography.regularNormal.copyWith(
                height: 24 / 16,
                color: colors.textMuted,
              ),
            ),
            SizedBox(height: AppSpacing.xxl),
            SizedBox(
              width: double.infinity,
              child: AppButtonPresets.primary(
                label: 'common.retry'.tr(),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shows a profile-completion error dialog and returns whether the user
/// chose to retry.
Future<bool?> showProfileCompletionErrorDialog({
  required BuildContext context,
  String? errorMessage,
}) {
  final barrierColor = context.appDialogTheme.spec.barrierColor;

  return showDialog<bool>(
    context: context,
    barrierColor: barrierColor,
    builder: (_) => _ProfileCompletionErrorDialog(errorMessage: errorMessage),
  );
}
