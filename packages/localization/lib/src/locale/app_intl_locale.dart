import 'package:easy_localization/easy_localization.dart'
    show DateFormat, NumberFormat;
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show DateFormat, NumberFormat;

/// ICU locale for [DateFormat]/[NumberFormat] when UI is in Arabic.
/// Product rule: always use Western digits (0–9) even in Arabic.
abstract final class AppIntlLocale {
  AppIntlLocale._();

  static const String _arabicWesternDigits = 'ar_AE';

  static String intlTag(Locale locale) => locale.languageCode == 'ar'
      ? _arabicWesternDigits
      : locale.toLanguageTag();

  static Locale materialPickerLocale(Locale uiLocale) =>
      uiLocale.languageCode == 'ar' ? const Locale('ar', 'AE') : uiLocale;

  static String westernizeDigits(String input) => input.replaceAllMapped(
    RegExp('[٠-٩۰-۹]'),
    (m) {
      final c = m[0]!.codeUnitAt(0);
      if (c >= 0x0660 && c <= 0x0669) {
        return String.fromCharCode(0x30 + c - 0x0660);
      }
      if (c >= 0x06F0 && c <= 0x06F9) {
        return String.fromCharCode(0x30 + c - 0x06F0);
      }
      return m[0]!;
    },
  );
}
