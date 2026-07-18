abstract final class UaePhoneValidator {
  UaePhoneValidator._();

  // Mobile: 05XXXXXXXX or 9715XXXXXXXX
  static final _mobileLocal = RegExp(r'^05[0-9]{8}$');
  static final _mobileIntl = RegExp(r'^9715[0-9]{8}$');

  // Landline: 0[2-9]XXXXXXX or 971[2-9]XXXXXXX
  static final _landlineLocal = RegExp(r'^0[2-9][0-9]{7}$');
  static final _landlineIntl = RegExp(r'^971[2-9][0-9]{7}$');

  static bool isValid(String? value) {
    if (value == null) return false;
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-+]'), '');
    if (cleaned.isEmpty) return false;
    return _mobileLocal.hasMatch(cleaned) ||
        _mobileIntl.hasMatch(cleaned) ||
        _landlineLocal.hasMatch(cleaned) ||
        _landlineIntl.hasMatch(cleaned);
  }

  static String? validationMessage(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    if (isValid(value)) return null;
    return 'validation.form.uae_phone_invalid';
  }

  static String normalize(String value) {
    final cleaned = value.trim().replaceAll(RegExp(r'[\s\-+]'), '');
    if (cleaned.startsWith('971')) return '+$cleaned';
    if (cleaned.startsWith('0')) return '+971${cleaned.substring(1)}';
    return '+971$cleaned';
  }
}
