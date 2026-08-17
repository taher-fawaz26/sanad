import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:sheet_navigation/sheet_navigation.dart';

/// Shows the language preferences sheet — Figma `3821:19032`.
///
/// Returns the confirmed language code (`en` / `ar`), or `null` when dismissed
/// without saving.
Future<String?> showLanguagePreferencesBottomSheet({
  required BuildContext context,
  required String initialLanguageCode,
}) {
  return SheetNavigator.push<String>(
    context,
    LanguagePreferencesBottomSheet(initialLanguageCode: initialLanguageCode),
    settings: const SheetRouteSettings(enableDrag: false),
  );
}

/// Single-select language sheet with [AppRadio] rows — Figma `3821:19032`.
class LanguagePreferencesBottomSheet extends StatefulWidget {
  const LanguagePreferencesBottomSheet({
    required this.initialLanguageCode,
    super.key,
  });

  final String initialLanguageCode;

  @override
  State<LanguagePreferencesBottomSheet> createState() =>
      _LanguagePreferencesBottomSheetState();
}

class _LanguagePreferencesBottomSheetState
    extends State<LanguagePreferencesBottomSheet> {
  static const _options = <_LanguageOption>[
    _LanguageOption(code: 'en', labelKey: 'app.english'),
    _LanguageOption(code: 'ar', labelKey: 'app.arabic'),
  ];

  late String _selectedCode;

  @override
  void initState() {
    super.initState();
    _selectedCode = widget.initialLanguageCode == 'en' ? 'en' : 'ar';
  }

  void _select(String code) => setState(() => _selectedCode = code);

  void _save() => Navigator.of(context).pop(_selectedCode);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _DragHandle(color: colors.border),
        SizedBox(height: AppSpacing.md),
        Text(
          'settings.section_language_preferences'.tr(),
          textAlign: TextAlign.center,
          style: typography.title3.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: AppSpacing.md),
        for (var i = 0; i < _options.length; i++) ...[
          if (i > 0) const AppDivider(),
          AppTableRow(
            title: _options[i].labelKey.tr(),
            trailing: AppTableTrailing.icon,
            trailingIcon: AppRadio<String>(
              value: _options[i].code,
              groupValue: _selectedCode,
              onChanged: (value) {
                if (value != null) _select(value);
              },
            ),
            onTap: () => _select(_options[i].code),
          ),
        ],
        SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'common.save'.tr(),
          onPressed: _save,
        ),
      ],
    );
  }
}

class _LanguageOption {
  const _LanguageOption({required this.code, required this.labelKey});

  final String code;
  final String labelKey;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Center(
        child: Container(
          width: 48,
          height: 5,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(100),
          ),
        ),
      ),
    );
  }
}
