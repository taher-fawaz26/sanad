abstract final class UaePhoneValidator {
  UaePhoneValidator._();

  // Mobile: 05XXXXXXXX, 5XXXXXXXX, or 9715XXXXXXXX
  static final _mobileLocal = RegExp(r'^05[0-9]{8}$');
  static final _mobileNational = RegExp(r'^5[0-9]{8}$');
  static final _mobileIntl = RegExp(r'^9715[0-9]{8}$');

  // Landline: 0[2-9]XXXXXXX, [2-9]XXXXXXX, or 971[2-9]XXXXXXX
  static final _landlineLocal = RegExp(r'^0[2-9][0-9]{7}$');
  static final _landlineNational = RegExp(r'^[2-9][0-9]{7}$');
  static final _landlineIntl = RegExp(r'^971[2-9][0-9]{7}$');

  static String _digitsOnly(String value) =>
      value.trim().replaceAll(RegExp(r'[\s\-+]'), '');

  static bool isValid(String? value) {
    if (value == null) return false;
    final cleaned = _digitsOnly(value);
    if (cleaned.isEmpty) return false;
    return _mobileLocal.hasMatch(cleaned) ||
        _mobileNational.hasMatch(cleaned) ||
        _mobileIntl.hasMatch(cleaned) ||
        _landlineLocal.hasMatch(cleaned) ||
        _landlineNational.hasMatch(cleaned) ||
        _landlineIntl.hasMatch(cleaned);
  }

  static String? validationMessage(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (isValid(value)) return null;
    return 'validation.form.uae_phone_invalid';
  }

  /// National digits for the phone field when `+971` is shown as a prefix.
  ///
  /// `+971500000006` / `971500000006` / `0500000006` → `500000006`.
  static String toNationalInput(String? value) {
    if (value == null) return '';
    final cleaned = _digitsOnly(value);
    if (cleaned.isEmpty) return '';
    if (cleaned.startsWith('971')) return cleaned.substring(3);
    if (cleaned.startsWith('0')) return cleaned.substring(1);
    return cleaned;
  }

  static String normalize(String value) {
    final cleaned = _digitsOnly(value);
    if (cleaned.startsWith('971')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+971${cleaned.substring(1)}';
    return '+971$cleaned';
  }
}
