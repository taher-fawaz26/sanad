/// Pure boolean email validation — no Flutter dependency.
abstract final class EmailValidator {
  EmailValidator._();

  static bool isValid(String? value) {
    if (value == null) return false;
    final v = value.trim();
    if (v.isEmpty) return false;
    return RegExp(r'^[\w.+-]+@[\w-]+\.[\w.]{2,}$').hasMatch(v);
  }
}
