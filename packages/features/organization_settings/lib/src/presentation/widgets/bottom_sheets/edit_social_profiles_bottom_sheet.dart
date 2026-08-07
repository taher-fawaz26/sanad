import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Editable organization social profile links.
@immutable
class SocialProfilesData {
  const SocialProfilesData({
    this.facebook,
    this.tiktok,
    this.instagram,
    this.x,
    this.websiteUrl,
  });

  final String? facebook;
  final String? tiktok;
  final String? instagram;
  final String? x;
  final String? websiteUrl;
}

/// Shows the social profiles edit bottom sheet — Figma `3809:18305`.
///
/// Returns updated [SocialProfilesData] when the user taps Save, or `null`
/// when dismissed without saving.
Future<SocialProfilesData?> showEditSocialProfilesBottomSheet({
  required BuildContext context,
  SocialProfilesData initial = const SocialProfilesData(),
}) {
  return SheetNavigator.push<SocialProfilesData>(
    context,
    _EditSocialProfilesSheetBody(initial: initial),
  );
}

class _EditSocialProfilesSheetBody extends StatefulWidget {
  const _EditSocialProfilesSheetBody({required this.initial});

  final SocialProfilesData initial;

  @override
  State<_EditSocialProfilesSheetBody> createState() =>
      _EditSocialProfilesSheetBodyState();
}

class _EditSocialProfilesSheetBodyState
    extends State<_EditSocialProfilesSheetBody> {
  late final TextEditingController _facebookController;
  late final TextEditingController _tiktokController;
  late final TextEditingController _instagramController;
  late final TextEditingController _xController;
  late final TextEditingController _websiteController;

  @override
  void initState() {
    super.initState();
    _facebookController = TextEditingController(text: widget.initial.facebook);
    _tiktokController = TextEditingController(text: widget.initial.tiktok);
    _instagramController = TextEditingController(
      text: widget.initial.instagram,
    );
    _xController = TextEditingController(text: widget.initial.x);
    _websiteController = TextEditingController(text: widget.initial.websiteUrl);
  }

  @override
  void dispose() {
    _facebookController.dispose();
    _tiktokController.dispose();
    _instagramController.dispose();
    _xController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.of(context).pop(
      SocialProfilesData(
        facebook: _trimOrNull(_facebookController.text),
        tiktok: _trimOrNull(_tiktokController.text),
        instagram: _trimOrNull(_instagramController.text),
        x: _trimOrNull(_xController.text),
        websiteUrl: _trimOrNull(_websiteController.text),
      ),
    );
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetHeader(title: 'settings.section_social'.tr()),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'settings.social_facebook'.tr(),
            hint: 'settings.social_facebook'.tr(),
            controller: _facebookController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            prefixIcon: _SocialPrefixIcon(asset: AppSvgs.socialFacebook),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'settings.social_tiktok'.tr(),
            hint: 'settings.social_tiktok'.tr(),
            controller: _tiktokController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            prefixIcon: _SocialPrefixIcon(asset: AppSvgs.socialTiktok),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'settings.social_instagram'.tr(),
            hint: 'settings.social_instagram'.tr(),
            controller: _instagramController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            prefixIcon: _SocialPrefixIcon(asset: AppSvgs.socialInstagram),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'settings.social_twitter'.tr(),
            hint: 'settings.social_twitter'.tr(),
            controller: _xController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.next,
            prefixIcon: _SocialPrefixIcon(asset: AppSvgs.socialTwitter),
          ),
          SizedBox(height: AppSpacing.lg),
          AppTextField(
            label: 'settings.social_website_url'.tr(),
            hint: 'settings.social_website_url'.tr(),
            controller: _websiteController,
            keyboardType: TextInputType.url,
            textInputAction: TextInputAction.done,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'settings.save_button'.tr(),
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.socialFacebook,
          width: AppDimension.iconMenu,
          height: AppDimension.iconMenu,
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          title,
          style: typography.title3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SocialPrefixIcon extends StatelessWidget {
  const _SocialPrefixIcon({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    return AppSvgPicture.asset(
      asset,
      width: AppDimension.iconMenu,
      height: AppDimension.iconMenu,
    );
  }
}
