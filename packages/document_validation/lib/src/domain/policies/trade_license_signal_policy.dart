/// Deterministic, multi-signal Trade License classifier applied to raw OCR
/// text — **not** a legal-validity check.
///
/// This answers exactly one question: *"does this look like a UAE Trade
/// License?"* It never attempts expiry, authenticity, ownership, or exact
/// field extraction — those remain the backend's job after upload. Because
/// on-device OCR is noisy (skew, glare, partial text, poor Arabic diacritic
/// handling), a single generic word (e.g. bare "License") must never decide
/// the outcome — [evaluate] requires at least one *strong* Trade License
/// term **and** either a license-number-like pattern or a second,
/// independent business/company signal before accepting.
///
/// Terminology is aligned with the fields the backend's own Trade License
/// extraction already recognizes (`licenseNumber`, `tradeNameEnglish`/
/// `tradeNameArabic`, `establishmentDate`, `licenceType`,
/// `unifiedLicenseNumber` — see
/// `apps/sanad_provider/.../data/models/extraction_response.dart`), so the
/// signals below are not an arbitrary keyword list but the same vocabulary
/// the rest of the app already treats as Trade-License-specific.
abstract final class TradeLicenseSignalPolicy {
  TradeLicenseSignalPolicy._();

  /// Strong, unambiguous Trade License phrases (English).
  static const _strongTermsEn = [
    'trade license',
    'trade licence',
    'commercial license',
    'commercial licence',
    'chamber of commerce',
  ];

  /// Strong, unambiguous Trade License phrases (Arabic). Includes both the
  /// definite (`ال...`) and indefinite article forms, since OCR frequently
  /// drops or mangles the leading `ال`.
  static const _strongTermsAr = [
    'رخصة تجارية',
    'رخصه تجاريه',
    'الرخصة التجارية',
    'الرخصه التجاريه',
    'غرفة تجارة',
    'غرفة التجارة',
    'الغرفة التجارية',
  ];

  /// Secondary business/company terms — vocabulary aligned to the backend's
  /// Trade License extraction fields. A single hit is not enough on its own
  /// (see class doc); at least two are required when no license-number-like
  /// pattern is present.
  static const _businessTermsEn = [
    'establishment',
    'company',
    'l.l.c',
    'llc',
    'activity',
    'legal form',
    'issue date',
    'issuing authority',
    'economic department',
  ];

  static const _businessTermsAr = [
    'المنشأة',
    'النشاط',
    'الشكل القانوني',
    'تاريخ الإصدار',
    'دائرة التنمية الاقتصادية',
    'الرقم الموحد',
  ];

  /// License-number-like patterns: a labeled number near a license/رخصة
  /// keyword, a `CN-######` style registration code, or a bare `DED` mark.
  static final List<RegExp> _licenseNumberPatterns = [
    RegExp(
      r'licen[sc]e\s*(no\.?|number)?\s*[:#]?\s*\d{4,}',
      caseSensitive: false,
    ),
    RegExp(r'\bcn[\s-]?\d{4,}\b', caseSensitive: false),
    RegExp(r'\bded\b', caseSensitive: false),
    RegExp(r'رقم\s*الرخصة\s*[:#]?\s*[0-9٠-٩]{4,}'),
  ];

  /// Minimum OCR text length below which the read is treated as too noisy to
  /// classify confidently, rather than a confident rejection.
  static const _kMinTextLength = 12;

  /// Whether [rawOcrText] looks like a UAE Trade License.
  ///
  /// Returns `false` for near-empty/too-short OCR output — that is "ask the
  /// user to retry with a clearer image", not a confident non-match, but
  /// both map to the same caller-facing outcome (no upload, retry prompt).
  static bool evaluate(String rawOcrText) {
    final text = _normalize(rawOcrText);
    if (text.length < _kMinTextLength) return false;

    final hasStrongTerm = _containsAny(text, _strongTermsEn) ||
        _containsAny(text, _strongTermsAr);
    if (!hasStrongTerm) return false;

    final hasLicenseNumber = _licenseNumberPatterns.any(
      (pattern) => pattern.hasMatch(text),
    );
    if (hasLicenseNumber) return true;

    final businessTermHits =
        _countMatches(text, _businessTermsEn) +
        _countMatches(text, _businessTermsAr);
    return businessTermHits >= 2;
  }

  /// Arabic diacritics (tashkeel, U+064B–U+0652), superscript alef
  /// (U+0670), and tatweel/kashida (U+0640) — stripped so OCR noise around
  /// vowel marks doesn't defeat a plain-text `contains` match. The exact
  /// codepoints are verified in the policy's test file (byte-level check)
  /// since the glyphs are visually indistinguishable in a diff.
  static final RegExp _arabicDiacritics = RegExp('[ً-ْٰـ]');

  /// Lower-cases (Latin script only — Arabic has no case), strips Arabic
  /// diacritics, and collapses whitespace.
  static String _normalize(String input) {
    final noDiacritics = input.replaceAll(_arabicDiacritics, '');
    return noDiacritics.toLowerCase().replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static bool _containsAny(String text, List<String> terms) =>
      terms.any(text.contains);

  static int _countMatches(String text, List<String> terms) =>
      terms.where(text.contains).length;
}
