import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:organization_settings/src/presentation/widgets/components/settings_social_field_view.dart';
import 'package:shared_ui/shared_ui.dart';

/// View-mode section displaying organization social profile links.
class SocialProfilesSection extends StatelessWidget {
  const SocialProfilesSection({
    super.key,
    this.facebook,
    this.tiktok,
    this.instagram,
    this.x,
    this.websiteUrl,
    this.onEdit,
  });

  final String? facebook;
  final String? tiktok;
  final String? instagram;
  final String? x;
  final String? websiteUrl;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_social'.tr(),

      onEdit: onEdit,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsSocialFieldView(
            label: 'settings.social_facebook'.tr(),
            iconAsset: AppSvgs.socialFacebook,
            value: facebook,
          ),
          SizedBox(height: AppSpacing.md),
          SettingsSocialFieldView(
            label: 'settings.social_tiktok'.tr(),
            iconAsset: AppSvgs.socialTiktok,
            value: tiktok,
          ),
          SizedBox(height: AppSpacing.md),
          SettingsSocialFieldView(
            label: 'settings.social_instagram'.tr(),
            iconAsset: AppSvgs.socialInstagram,
            value: instagram,
          ),
          SizedBox(height: AppSpacing.md),
          SettingsSocialFieldView(
            label: 'settings.social_twitter'.tr(),
            iconAsset: AppSvgs.socialTwitter,
            value: x,
          ),
          SizedBox(height: AppSpacing.md),
          SettingsSocialFieldView(
            label: 'settings.social_website_url'.tr(),
            value: websiteUrl,
          ),
        ],
      ),
    );
  }
}
