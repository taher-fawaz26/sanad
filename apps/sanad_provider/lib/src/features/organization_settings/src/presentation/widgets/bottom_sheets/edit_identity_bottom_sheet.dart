import 'package:app_assets/app_assets.dart';
import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Backend cap on `UpdateServiceProviderSettingsDto.description`.
const _kBusinessDescriptionMaxLength = 350;

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
  final _formKey = GlobalKey<FormState>();
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(colors: colors, typography: typography),
            SizedBox(height: AppSpacing.xxl),
            _BusinessDescriptionField(
              controller: _controller,
              onEnhanceWithAi: widget.onEnhanceWithAi,
            ),
            SizedBox(height: AppSpacing.xl),
            AppButton(
              label: 'common.save'.tr(),
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(_controller.text);
  }
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
    this.onEnhanceWithAi,
  });

  final TextEditingController controller;
  final VoidCallback? onEnhanceWithAi;

  @override
  Widget build(BuildContext context) {
    return AppDescriptionField(
      controller: controller,
      label: 'settings.business_description'.tr(),
      maxLines: 5,
      maxLength: _kBusinessDescriptionMaxLength,
      validator: (value) {
        final trimmed = value?.trim() ?? '';
        if (trimmed.isNotEmpty && !MeaningfulTextValidator.isValid(trimmed)) {
          return 'validation.meaningless_text'.tr();
        }
        if (!LengthValidator.isValid(
          value,
          maxLength: _kBusinessDescriptionMaxLength,
        )) {
          return 'validation.length_max'.tr(
            namedArgs: {'max': '$_kBusinessDescriptionMaxLength'},
          );
        }
        return null;
      },
      aiActionLabel: 'common.enhance_with_ai'.tr(),
      onImproveWithAi: onEnhanceWithAi,
    );
  }
}
