import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
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
    settings: const SheetRouteSettings(
      enableDrag: false,
      padChild: false,
    ),
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
    if (trimmed.isEmpty) {
      setState(() => _errorText = 'settings.name_required_error'.tr());
      return;
    }
    Navigator.of(context).pop(trimmed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return AppActionSheet(
      showCancel: false,
      footer: AppButton(
        label: 'settings.save_button'.tr(),
        onPressed: _submit,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'settings.edit_name_title'.tr(),
              textAlign: TextAlign.center,
              style: typography.title3.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}
