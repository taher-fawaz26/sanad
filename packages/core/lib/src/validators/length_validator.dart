/// String length validation — pure Dart, no Flutter dependency.
///
/// Parameterized rather than one class per field, since the backend
/// contract enforces the same shape (`minLength`/`maxLength` on a trimmed
/// string) with different bounds per field (e.g. person/business names vs.
/// role names vs. descriptions).
abstract final class LengthValidator {
  LengthValidator._();

  static bool isValid(String? value, {int? minLength, int? maxLength}) {
    final length = (value ?? '').trim().length;
    if (minLength != null && length < minLength) return false;
    if (maxLength != null && length > maxLength) return false;
    return true;
  }
}
