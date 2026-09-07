/// Chooses which speech-recognition locale to ask the device for.
///
/// Pure, and deliberately in the domain layer: the mapping from "the app is in
/// Arabic" to "ask for `ar-AE`" is a product decision, not a plugin detail and
/// not something a widget should be spelling out. `localization.md` forbids
/// `Locale` literals scattered through the app for exactly this reason.
///
/// The device is the authority on what it can actually recognise, so this takes
/// the recognizer's own list and picks from it rather than asserting a tag and
/// hoping. When nothing matches it returns `null`, which means *let the device
/// decide* — the graceful path when a language has no recognizer installed,
/// rather than an error the user can do nothing about.
abstract final class SpeechLocaleResolver {
  /// Preferred recognition tags per app language, best first.
  ///
  /// Arabic leads with `ar-AE` to match `AppIntlLocale.intlTag`, which already
  /// encodes the product's "Arabic means the UAE" decision for number and date
  /// formatting. `ar-SA` is the fallback because it is the Arabic locale most
  /// widely shipped by recognizers.
  static const Map<String, List<String>> preferences = {
    'ar': ['ar-AE', 'ar-SA', 'ar-EG'],
    'en': ['en-US', 'en-GB', 'en-AE'],
  };

  /// Picks the best available tag for [languageCode], or `null` for none.
  ///
  /// [available] is whatever the device reported, in whatever shape it reported
  /// it — Android returns `ar_AE`, iOS returns `ar-AE`, and case is not
  /// guaranteed, so everything is normalised before comparison.
  static String? resolve({
    required String languageCode,
    required List<String> available,
  }) {
    final language = _normalise(languageCode).split('-').first;
    if (language.isEmpty || available.isEmpty) return null;

    // Compare on normalised tags but hand back the device's own spelling —
    // passing back a re-cased tag it did not offer is how a valid locale gets
    // silently rejected.
    final byNormalised = <String, String>{};
    for (final tag in available) {
      byNormalised.putIfAbsent(_normalise(tag), () => tag);
    }

    for (final preferred in preferences[language] ?? const <String>[]) {
      final match = byNormalised[_normalise(preferred)];
      if (match != null) return match;
    }

    // No preferred region, but the language itself may still be there under a
    // region we did not think of — a bare `ar`, or `en-IN`.
    for (final entry in byNormalised.entries) {
      if (entry.key == language || entry.key.startsWith('$language-')) {
        return entry.value;
      }
    }

    return null;
  }

  /// Lower-cases and settles on `-` as the separator.
  static String _normalise(String tag) =>
      tag.trim().toLowerCase().replaceAll('_', '-');
}
