import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// Country-aware phone validation backed by `phone_numbers_parser`.
abstract final class PhoneValidator {
  PhoneValidator._();

  static const Set<String> strictCountries = <String>{
    'AE',
    'EG',
    'SA',
    'JO',
    'QA',
    'KW',
    'BH',
    'OM',
  };

  static bool isValid(
    String? value, {
    IsoCode? country,
    PhoneNumberType? type = PhoneNumberType.mobile,
  }) {
    if (value == null || value.trim().isEmpty) return false;
    final trimmed = value.trim();
    try {
      final phone = country != null
          ? PhoneNumber.parse(trimmed, callerCountry: country)
          : PhoneNumber.parse(trimmed);
      final effectiveIso = (country ?? phone.isoCode).name.toUpperCase();
      if (strictCountries.contains(effectiveIso)) {
        return phone.isValid(type: type);
      }
    } on Object catch (_) {
      return false;
    }
    final digits = trimmed.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 7 && digits.length <= 15;
  }

  static IsoCode? isoCodeFromName(String? alpha2) {
    if (alpha2 == null || alpha2.isEmpty) return null;
    try {
      return IsoCode.values.byName(alpha2.toUpperCase());
    } on Object catch (_) {
      return null;
    }
  }
}
