/// Generic required-field validation — pure Dart, no Flutter dependency.
abstract final class RequiredValidator {
  RequiredValidator._();

  static bool isValid(String? value) {
    if (value == null) return false;
    return value.trim().isNotEmpty;
  }
}
