import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:otp/src/domain/enums/otp_channel.dart';

/// Check-badge confirmation screen shown after a successful verification,
/// matching the Figma "Email Verified!" / "Phone Verified!" screens.
class OtpSuccessView extends StatelessWidget {
  const OtpSuccessView({required this.channel, super.key});

  final OtpChannel channel;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final isEmail = channel == OtpChannel.email;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.xxl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: 0.1),
            ),
            child: Icon(Icons.check_circle, color: colors.primary, size: 40),
          ),
          SizedBox(height: AppSpacing.lg),
          Text(
            isEmail
                ? 'otp.success_title_email'.tr()
                : 'otp.success_title_phone'.tr(),
            style: typography.title3.copyWith(
              fontWeight: FontWeight.w700,
              color: colors.primary,
            ),
          ),
          SizedBox(height: AppSpacing.sm),
          Text(
            isEmail
                ? 'otp.success_subtitle_email'.tr()
                : 'otp.success_subtitle_phone'.tr(),
            textAlign: TextAlign.center,
            style: typography.regularNormal.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
