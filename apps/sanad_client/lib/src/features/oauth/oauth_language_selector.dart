import 'package:app_assets/app_assets.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';

/// Language selector chip for the OAuth screen (Figma `6979:27141`).
///
/// Not a reuse of `packages/auth`'s `LanguageDropdown` — that widget renders
/// a plain bordered box with no flag, which doesn't match this Figma chip,
/// and it's out of scope to modify (shared with `sanad_provider`). This
/// widget performs the same two-step locale sync `LanguageDropdown` does:
/// `context.setLocale()` (drives `.tr()`/RTL) and [TranslateBloc] (source of
/// truth for the network layer's `Accept-Language` header) — both are
/// required, kept in sync at this one call site.
///
/// Flag emoji only — no SVG flag assets, per the design brief.
class OAuthLanguageSelector extends StatelessWidget {
  /// Creates an [OAuthLanguageSelector].
  const OAuthLanguageSelector({super.key});

  static const _english = Locale('en', 'US');
  static const _arabic = Locale('ar', 'AR');

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final typography = context.appTypography;
    // Reads Flutter's own ambient Localizations rather than easy_localization's
    // `context.locale` — the latter requires a live EasyLocalization ancestor
    // and throws otherwise; MaterialApp's `locale:` is already driven by
    // `context.locale` one level up (see app.dart), so this resolves to the
    // same value at runtime with a softer dependency.
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return PopupMenuButton<Locale>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.circularLg),
      child: Container(
        height: responsiveDimension(40),
        padding: EdgeInsets.symmetric(
          horizontal: responsiveDimension(AppSpacing.sm),
        ),
        decoration: BoxDecoration(
          color: colors.surfaceVariant,
          borderRadius: AppRadius.circularLg,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isArabic ? '🇦🇪' : '🇬🇧',
              style: const TextStyle(fontSize: 20),
            ),
            SizedBox(width: responsiveDimension(AppSpacing.xs)),
            Text(
              isArabic ? 'العربية' : 'English',
              style: typography.smallNormal.copyWith(
                color: colors.textPrimary,
              ),
            ),
            SizedBox(width: responsiveDimension(AppSpacing.xs)),
            AppSvgPicture.asset(
              AppSvgs.chevronDown,
              width: responsiveDimension(AppDimension.iconSm),
              height: responsiveDimension(AppDimension.iconSm),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(value: _english, child: Text('🇬🇧  English')),
        const PopupMenuItem(value: _arabic, child: Text('🇦🇪  العربية')),
      ],
      onSelected: (locale) async {
        // Two systems must stay in sync (mirrors LanguageDropdown):
        //   1. EasyLocalization — drives `.tr()` and RTL/LTR rebuilds.
        //   2. TranslateBloc     — source of truth for `Accept-Language`.
        await context.setLocale(locale);
        if (!context.mounted) return;
        context.read<TranslateBloc>().add(
          locale.languageCode == 'ar' ? TrArabicEvent() : TrEnglishEvent(),
        );
      },
    );
  }
}
