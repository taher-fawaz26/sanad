import 'package:flutter/widgets.dart';

/// The app's supported languages — the single vocabulary for "what language is
/// the app in".
///
/// Every [Locale] the app can run in is defined here and nowhere else.
/// `EasyLocalization`'s `setLocale` asserts
/// `supportedLocales.contains(locale)`, so a second literal `Locale('ar','AR')`
/// somewhere else is a latent crash the moment the two drift apart; owning both
/// the individual locales and [supportedLocales] in one enum makes that
/// impossible.
enum AppLanguage {
  /// Arabic (RTL).
  arabic('ar', Locale('ar', 'AR')),

  /// English (LTR) — the product default.
  english('en', Locale('en', 'US'))
  ;

  const AppLanguage(this.code, this.locale);

  /// The two-letter API code (`ar` / `en`) sent as `Accept-Language` / `x-lang`
  /// and used as the language component of every language-keyed cache key.
  final String code;

  /// The Flutter locale this language renders as.
  final Locale locale;

  /// The product default for a user with no persisted preference.
  static const AppLanguage defaultLanguage = english;

  /// The locale list passed to `EasyLocalization.supportedLocales`.
  ///
  /// Must stay in lockstep with the enum — `app_language_test.dart` asserts
  /// that it contains exactly every [AppLanguage.locale].
  static const List<Locale> supportedLocales = [
    Locale('ar', 'AR'),
    Locale('en', 'US'),
  ];

  /// The locale `EasyLocalization` falls back to for a missing translation.
  static const Locale fallbackLocale = Locale('en', 'US');

  /// Parses a language code, or returns `null` when it names no supported
  /// language.
  ///
  /// Accepts a bare code (`ar`), a BCP-47 tag (`en-US`) and Dart's
  /// `Locale.toString()` form (`ar_AR`) — only the primary subtag is
  /// significant, and matching is case-insensitive. Whitespace is tolerated so
  /// a value read straight out of storage never needs pre-cleaning.
  static AppLanguage? tryFromCode(String? code) {
    final primary = code?.trim().toLowerCase().split(RegExp('[-_]')).first;
    if (primary == null || primary.isEmpty) return null;
    for (final language in values) {
      if (language.code == primary) return language;
    }
    return null;
  }

  /// Like [tryFromCode] but resolves an unknown code to [fallback].
  static AppLanguage fromCode(
    String? code, {
    AppLanguage fallback = defaultLanguage,
  }) => tryFromCode(code) ?? fallback;

  /// Whether this language lays out right-to-left.
  bool get isRtl => this == arabic;

  /// i18n key for this language's own name, as shown in a language picker.
  ///
  /// Lives on the enum so every picker and settings row resolves the label the
  /// same way, instead of each re-deriving it from a code string with its own
  /// fallback (which is how an Arabic UI ended up labelled "English").
  String get labelKey => switch (this) {
    arabic => 'app.arabic',
    english => 'app.english',
  };
}
