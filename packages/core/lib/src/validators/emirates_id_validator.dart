/// UAE Emirates ID validation — pure Dart, no Flutter.
abstract final class EmiratesIdValidator {
  EmiratesIdValidator._();

  static const int requiredDigitCount = 15;
  static const String icaIssuerPrefix = '784';
  static final RegExp _fullPattern = RegExp(r'^784\d{12}$');

  static String normalizeDigits(String? raw) =>
      raw == null ? '' : raw.replaceAll(RegExp(r'\D'), '');

  static String? formatApiHyphenated(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final d = normalizeDigits(raw);
    if (d.length == requiredDigitCount && _fullPattern.hasMatch(d)) {
      return '${d.substring(0, 3)}-${d.substring(3, 7)}-'
          '${d.substring(7, 14)}-${d.substring(14)}';
    }
    return trimmed;
  }

  static bool isValid(String? raw) {
    final d = normalizeDigits(raw);
    return d.length == requiredDigitCount && _fullPattern.hasMatch(d);
  }
}
