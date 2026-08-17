/// Meaningful free-text validation — pure Dart.
///
/// Rejects values with no human-readable content: null, empty,
/// whitespace-only, or made up entirely of punctuation/symbols/digits with
/// no letter present. Does not restrict which punctuation, digits, or
/// symbols may appear alongside real text — that is the caller's/other
/// validators' concern.
abstract final class MeaningfulTextValidator {
  MeaningfulTextValidator._();

  static final RegExp _letterPattern = RegExp(r'\p{L}', unicode: true);

  static bool isValid(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    return _letterPattern.hasMatch(trimmed);
  }
}
