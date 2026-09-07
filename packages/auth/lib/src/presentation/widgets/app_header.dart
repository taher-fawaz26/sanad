import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:localization/localization.dart';

/// Language selector dropdown for app header.
class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;
    final colors = context.appColors;

    return PopupMenuButton<AppLanguage>(
      offset: const Offset(0, 48),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: colors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              currentLocale.languageCode == 'ar' ? 'العربية' : 'English',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 20,
              color: colors.textPrimary,
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: AppLanguage.english,
          child: Row(
            children: [
              if (currentLocale.languageCode == 'en')
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
              const Text('English'),
            ],
          ),
        ),
        PopupMenuItem(
          value: AppLanguage.arabic,
          child: Row(
            children: [
              if (currentLocale.languageCode == 'ar')
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Icon(
                    Icons.check,
                    size: 20,
                    color: colors.primary,
                  ),
                ),
              const Text('العربية'),
            ],
          ),
        ),
      ],
      // The app's single language entry point: TranslateBloc owns the
      // language and AppLocaleSync applies it to EasyLocalization.
      onSelected: context.setAppLanguage,
    );
  }
}

/// App header with logo and language selector.
class AppHeader extends StatelessWidget {
  const AppHeader({
    super.key,
    this.logoAssetPath = 'assets/images/logo.png',
  });

  /// Asset path declared in the host app (e.g. `apps/sanad_provider/assets`).
  final String logoAssetPath;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Image.asset(
              logoAssetPath,
              height: 32,
              fit: BoxFit.contain,
              alignment: AlignmentDirectional.centerStart,
            ),
          ),
          const SizedBox(width: 12),
          const LanguageDropdown(),
        ],
      ),
    );
  }
}
