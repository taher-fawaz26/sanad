import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

/// Language preferences section — Figma `3821:18893`.
class LanguagePreferencesSection extends StatelessWidget {
  const LanguagePreferencesSection({
    required this.selectedLanguageLabel,
    required this.onTap,
    super.key,
  });

  final String selectedLanguageLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppSectionCard(
      title: 'settings.section_language_preferences'.tr(),
      child: AppSelectField(
        label: 'settings.language'.tr(),
        value: selectedLanguageLabel,
        isRequired: true,
        onTap: onTap,
      ),
    );
  }
}
