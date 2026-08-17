/// Person name validation — pure Dart.
abstract final class PersonNameValidator {
  PersonNameValidator._();

  static final RegExp _wordPattern = RegExp(r"^[\p{L}'\-]+$", unicode: true);

  /// [minWords] defaults to 2 (first + last name). Pass 1 for fields where a
  /// single-word name is a legitimate business case (e.g. a worker
  /// registered under one name).
  static bool isValid(String? value, {int minWords = 2}) {
    if (value == null || value.trim().isEmpty) return false;
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.length < minWords) return false;
    return words.every(_wordPattern.hasMatch);
  }
}
