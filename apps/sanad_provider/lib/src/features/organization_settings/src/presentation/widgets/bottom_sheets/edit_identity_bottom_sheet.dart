import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the edit identity bottom sheet.
///
/// Returns the updated business description when the user taps Save,
/// or `null` if dismissed without saving.
Future<String?> showEditIdentityBottomSheet({
  required BuildContext context,
  String? initialDescription,
  VoidCallback? onEnhanceWithAi,
}) {
  return SheetNavigator.push<String>(
    context,
    _EditIdentitySheetBody(
      initialDescription: initialDescription,
      onEnhanceWithAi: onEnhanceWithAi,
    ),
  );
}

class _EditIdentitySheetBody extends StatefulWidget {
  const _EditIdentitySheetBody({
    this.initialDescription,
    this.onEnhanceWithAi,
  });

  final String? initialDescription;
  final VoidCallback? onEnhanceWithAi;

  @override
  State<_EditIdentitySheetBody> createState() => _EditIdentitySheetBodyState();
}

class _EditIdentitySheetBodyState extends State<_EditIdentitySheetBody> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialDescription ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(colors: colors, typography: typography),
          SizedBox(height: AppSpacing.xxl),
          _BusinessDescriptionField(
            controller: _controller,
            colors: colors,
            typography: typography,
            onEnhanceWithAi: widget.onEnhanceWithAi,
          ),
          SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'settings.save_button'.tr(),
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  void _submit() => Navigator.of(context).pop(_controller.text);
}

class _Header extends StatelessWidget {
  const _Header({required this.colors, required this.typography});

  final AppColors colors;
  final AppTypography typography;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppSvgPicture.asset(
          AppSvgs.registrationCity,
          width: 24,
          height: 24,
          colorFilter: ColorFilter.mode(colors.primary, BlendMode.srcIn),
        ),
        SizedBox(height: AppSpacing.md),
        Text(
          'settings.section_identity'.tr(),
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

class _BusinessDescriptionField extends StatelessWidget {
  const _BusinessDescriptionField({
    required this.controller,
    required this.colors,
    required this.typography,
    this.onEnhanceWithAi,
  });

  final TextEditingController controller;
  final AppColors colors;
  final AppTypography typography;
  final VoidCallback? onEnhanceWithAi;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'settings.business_description'.tr(),
          style: typography.smallNormal.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: colors.surface,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: typography.smallNormal.copyWith(
                  color: colors.textPrimary,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: AppSpacing.xxl),
              AppEnhanceWithAiButton(
                label: 'settings.enhance_with_ai'.tr(),
                onTap: onEnhanceWithAi,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
