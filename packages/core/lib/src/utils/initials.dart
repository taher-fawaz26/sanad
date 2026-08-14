/// Extracts up to two uppercase initials from a person's name — pure Dart.
///
/// Takes the first letter of each of the first two non-empty,
/// whitespace-separated words. Returns `null` for a `null`, empty, or
/// whitespace-only [name].
///
/// Examples: `"Ali Hassan"` → `"AH"`, `"Taher"` → `"T"`, `""`/`null` → `null`.
String? initialsOf(String? name) {
  final trimmed = name?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}
