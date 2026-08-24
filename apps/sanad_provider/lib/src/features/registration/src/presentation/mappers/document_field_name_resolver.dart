import 'package:easy_localization/easy_localization.dart';

/// Resolves a raw backend field identifier (e.g. `full_name_english`,
/// `license_number`) to its localized, human-readable label.
///
/// The backend's `auth/extract` rejection returns machine field identifiers
/// under `fields[]` (snake_case or camelCase, English only) alongside its
/// `message`. Those identifiers must never reach the UI verbatim — this is
/// the single, centralized mapping point so no widget hardcodes a raw
/// backend token. Reuses the same `registration.*` localization keys already
/// used to label the extracted-field grid, so every id resolves to text that
/// exists in both `en-US.json` and `ar-AR.json`.
///
/// Normalization strips separators/case before lookup so `full_name_english`,
/// `fullNameEnglish`, and `FULL_NAME_ENGLISH` all resolve the same way.
String resolveDocumentFieldLabel(String rawField) {
  final key = _localizationKeyFor(_normalize(rawField));
  if (key != null) return key.tr();
  return _humanize(rawField);
}

/// Resolves and joins a list of raw backend field identifiers into one
/// localized, comma-separated string for interpolation into a banner
/// message. Deduplicates by normalized identity so aliasing the same field
/// twice (e.g. `license_number` and `licenseNumber` in the same response)
/// only shows once.
String describeMissingFields(List<String> rawFields) {
  final seen = <String>{};
  final labels = <String>[];
  for (final field in rawFields) {
    final normalized = _normalize(field);
    if (normalized.isEmpty || !seen.add(normalized)) continue;
    labels.add(resolveDocumentFieldLabel(field));
  }
  return labels.join('registration.field_list_separator'.tr());
}

String _normalize(String raw) =>
    raw.toLowerCase().replaceAll(RegExp('[^a-z]'), '');

const Map<String, String> _fieldKeysByNormalizedToken = {
  'fullnameenglish': 'registration.full_name_en',
  'fullnameen': 'registration.full_name_en',
  'fullnamearabic': 'registration.full_name_ar',
  'fullnamear': 'registration.full_name_ar',
  'idnumber': 'registration.id_number',
  'emiratesid': 'registration.id_number',
  'emiratesidnumber': 'registration.id_number',
  'nationality': 'registration.nationality',
  'dateofbirth': 'registration.date_of_birth',
  'dob': 'registration.date_of_birth',
  'expirydate': 'registration.expiry_date',
  'expiry': 'registration.expiry_date',
  'gender': 'registration.gender',
  'licensenumber': 'registration.licence_no',
  'licencenumber': 'registration.licence_no',
  'licenseno': 'registration.licence_no',
  'licenceno': 'registration.licence_no',
  'licensetype': 'registration.licence_type',
  'licencetype': 'registration.licence_type',
  'establishmentdate': 'registration.establishment_date',
  'issuancedate': 'registration.issuance_date',
  'legalform': 'registration.legal_form',
  'unifiedregistrationnumber': 'registration.unified_reg_no',
  'unifiedregno': 'registration.unified_reg_no',
  'unifiedlicensenumber': 'registration.unified_licence_no',
  'unifiedlicencenumber': 'registration.unified_licence_no',
  'unifiedlicenceno': 'registration.unified_licence_no',
  'tradenameenglish': 'registration.trade_name_en',
  'tradenameen': 'registration.trade_name_en',
  'tradenamearabic': 'registration.trade_name_ar',
  'tradenamear': 'registration.trade_name_ar',
  'tradename': 'registration.trade_name_en',
};

String? _localizationKeyFor(String normalized) =>
    _fieldKeysByNormalizedToken[normalized];

/// Fallback for a field identifier this resolver doesn't recognize: turns
/// `some_raw_field` into `Some Raw Field` rather than showing the raw,
/// internal-looking token.
String _humanize(String raw) {
  final words = raw
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .replaceAllMapped(
        RegExp('([a-z0-9])([A-Z])'),
        (m) => '${m[1]} ${m[2]}',
      )
      .trim();
  if (words.isEmpty) return raw;
  return words
      .split(RegExp(r'\s+'))
      .map(
        (w) =>
            w.isEmpty ? w : w[0].toUpperCase() + w.substring(1).toLowerCase(),
      )
      .join(' ');
}
