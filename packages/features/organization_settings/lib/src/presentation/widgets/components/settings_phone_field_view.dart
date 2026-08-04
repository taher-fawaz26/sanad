import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_verified_field_view.dart';

/// Read-only phone field for general settings view mode.
///
/// Shows UAE flag, country code, number, and an optional tappable change link.
class SettingsPhoneFieldView extends StatelessWidget {
  const SettingsPhoneFieldView({
    super.key,
    required this.phone,
    this.label,
    this.onChangeTap,
    this.showVerifiedBadge = true,
  });

  static const String countryCode = '+971';

  final String phone;
  final String? label;
  final VoidCallback? onChangeTap;
  final bool showVerifiedBadge;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    final fieldLabel = label ?? 'settings.phone_number'.tr();

    return SettingsVerifiedFieldView(
      label: fieldLabel,
      showVerifiedBadge: showVerifiedBadge,
      child: Row(
        children: [
          AppSvgPicture.asset(
            AppSvgs.flagAe,
            width: AppDimension.iconLg,
            height: AppDimension.iconLg,
          ),
          SizedBox(width: AppSpacing.sm),
          Text(
            countryCode,
            style: typography.regularNone.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              phone,
              style: typography.regularNone.copyWith(color: colors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (onChangeTap != null) ...[
            SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: onChangeTap,
              child: Text(
                'settings.change'.tr(),
                style: typography.smallNormal.copyWith(
                  color: colors.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: colors.primary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
