import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localization/localization.dart';

void main() {
  group('AppLanguage', () {
    test('English is the product default', () {
      expect(AppLanguage.defaultLanguage, AppLanguage.english);
      expect(AppLanguage.fallbackLocale, const Locale('en', 'US'));
    });

    test('supportedLocales contains exactly every language locale', () {
      // Guards EasyLocalization's `assert(supportedLocales.contains(locale))`:
      // a language whose locale is missing from this list crashes the moment
      // the user switches to it.
      expect(
        AppLanguage.supportedLocales.toSet(),
        AppLanguage.values.map((l) => l.locale).toSet(),
      );
      expect(
        AppLanguage.supportedLocales.length,
        AppLanguage.values.length,
        reason: 'no duplicate or stray locales',
      );
    });

    test('tryFromCode reads the primary subtag, case-insensitively', () {
      for (final code in ['ar', 'AR', 'ar-AR', 'ar_AR', 'ar-AE', ' ar ']) {
        expect(AppLanguage.tryFromCode(code), AppLanguage.arabic, reason: code);
      }
      for (final code in ['en', 'EN', 'en-US', 'en_US', 'en-GB']) {
        expect(
          AppLanguage.tryFromCode(code),
          AppLanguage.english,
          reason: code,
        );
      }
    });

    test('tryFromCode returns null for an unsupported or empty code', () {
      for (final code in [null, '', '   ', 'fr', 'de-DE', '-', 'zz']) {
        expect(AppLanguage.tryFromCode(code), isNull, reason: '$code');
      }
    });

    test('fromCode falls back to English, not Arabic', () {
      expect(AppLanguage.fromCode(null), AppLanguage.english);
      expect(AppLanguage.fromCode('fr'), AppLanguage.english);
      expect(AppLanguage.fromCode('ar'), AppLanguage.arabic);
      expect(
        AppLanguage.fromCode('fr', fallback: AppLanguage.arabic),
        AppLanguage.arabic,
      );
    });

    test('isRtl is true only for Arabic', () {
      expect(AppLanguage.arabic.isRtl, isTrue);
      expect(AppLanguage.english.isRtl, isFalse);
    });
  });
}
