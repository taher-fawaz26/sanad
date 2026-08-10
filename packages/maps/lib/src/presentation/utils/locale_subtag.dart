/// Normalizes a locale identifier (`ar`, `ar_AE`, `en-US`) to the language
/// subtag Google's `language` query param expects (`ar`, `en`). Returns null
/// when the identifier is null/empty so the caller can omit the param.
///
/// Shared by every Google HTTP call site (reverse geocoding, autocomplete) so
/// language handling is consistent across the discovery and search paths.
String? localeSubtag(String? identifier) {
  if (identifier == null || identifier.isEmpty) return null;
  final subtag = identifier.split(RegExp('[_-]')).first;
  return subtag.isEmpty ? null : subtag;
}
