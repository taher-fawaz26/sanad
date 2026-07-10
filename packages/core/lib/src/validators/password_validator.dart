/// Strong-password boolean validation — no Flutter dependency.
abstract final class PasswordValidator {
  PasswordValidator._();

  static const int minLength = 8;

  static final RegExp _special = RegExp(
    r'[!@#$%^&*()_+\-=\[\]{};:,.<>?/\\|`~]',
  );

  static bool isValid(String? value) {
    if (value == null || value.isEmpty) return false;
    if (value.length < minLength) return false;
    if (!value.contains(RegExp('[a-z]'))) return false;
    if (!value.contains(RegExp('[A-Z]'))) return false;
    if (!value.contains(RegExp('[0-9]'))) return false;
    if (!value.contains(_special)) return false;
    return true;
  }
}
