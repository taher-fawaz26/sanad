/// Person name validation — pure Dart.
abstract final class PersonNameValidator {
  PersonNameValidator._();

  static final RegExp _wordPattern = RegExp(r"^[\p{L}'\-]+$", unicode: true);

  static bool isValid(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < 2) return false;
    return words.every(_wordPattern.hasMatch);
  }
}
