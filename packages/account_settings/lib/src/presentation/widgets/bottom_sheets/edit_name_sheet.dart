import 'package:core/core.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the edit-name sheet.
///
/// Returns the trimmed name when the user taps Save, or `null` if dismissed
/// without saving or the field was left empty.
Future<String?> showEditNameSheet({
  required BuildContext context,
  String? initialName,
}) {
  return SheetNavigator.push<String>(
    context,
    _EditNameSheetBody(initialName: initialName),
    settings: const SheetRouteSettings(enableDrag: false),
  );
}

class _EditNameSheetBody extends StatefulWidget {
  const _EditNameSheetBody({this.initialName});

  final String? initialName;

  @override
  State<_EditNameSheetBody> createState() => _EditNameSheetBodyState();
}

class _EditNameSheetBodyState extends State<_EditNameSheetBody> {
  late final TextEditingController _controller;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _controller.text.trim();
    if (!RequiredValidator.isValid(trimmed)) {
      setState(() => _errorText = 'settings.name_required_error'.tr());
      return;
    }
    // minWords: 1 — a single-word name is a legitimate account owner name,
    // matching the same allowance used elsewhere in the app (e.g. workers).
    if (!PersonNameValidator.isValid(trimmed, minWords: 1)) {
      setState(() => _errorText = 'validation.invalid_name'.tr());
      return;
    }
    if (!LengthValidator.isValid(trimmed, minLength: 2, maxLength: 255)) {
      setState(
        () => _errorText = 'validation.length_range'.tr(
          namedArgs: {'min': '2', 'max': '255'},
        ),
      );
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SettingsSheetTitle(title: 'settings.edit_name_title'.tr()),
        SizedBox(height: AppSpacing.xxl),
        AppTextField(
          label: 'settings.name'.tr(),
          hint: 'settings.name_hint'.tr(),
          controller: _controller,
          autofocus: true,
          errorText: _errorText,
          onChanged: (_) {
            if (_errorText != null) setState(() => _errorText = null);
          },
        ),
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'common.save'.tr(),
          onPressed: _submit,
        ),
      ],
    );
  }
}
