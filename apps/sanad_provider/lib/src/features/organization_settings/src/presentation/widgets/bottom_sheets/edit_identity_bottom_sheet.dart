import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';
import 'package:text_optimization/text_optimization.dart';

/// Backend cap on `UpdateServiceProviderSettingsDto.description`.
const _kBusinessDescriptionMaxLength = 350;

/// Shows the edit identity bottom sheet.
///
/// Returns the updated business description when the user taps Save,
/// or `null` if dismissed without saving.
Future<String?> showEditIdentityBottomSheet({
  required BuildContext context,
  String? initialDescription,
}) {
  return SheetNavigator.push<String>(
    context,
    _EditIdentitySheetBody(initialDescription: initialDescription),
  );
}

class _EditIdentitySheetBody extends StatefulWidget {
  const _EditIdentitySheetBody({this.initialDescription});

  final String? initialDescription;

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
            SettingsSheetTitle(title: 'settings.section_identity'.tr()),
            SizedBox(height: AppSpacing.xxl),
            _BusinessDescriptionField(controller: _controller),
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

class _BusinessDescriptionField extends StatelessWidget {
  const _BusinessDescriptionField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return AiEnhanceDescriptionField(
      controller: controller,
      label: 'settings.business_description'.tr(),
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
    );
  }
}
