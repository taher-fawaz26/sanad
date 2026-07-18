/// Returns up to two uppercase initials from a person's full name.
///
/// Examples: `"Ali Hassan"` → `"AH"`, `"Taher"` → `"T"`, `""` → `""`.
String personInitials(String name) {
  final words = name.trim().split(RegExp(r'\s+'));
  return words
      .where((w) => w.isNotEmpty)
      .take(2)
      .map((w) => w[0].toUpperCase())
      .join();
}
