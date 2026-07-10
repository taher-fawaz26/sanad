/// URL validation — pure Dart.
abstract final class UrlValidator {
  UrlValidator._();

  static final RegExp googleMapsRegex = RegExp(
    r'^https?://(maps\.google\.[a-z]{2,}(/|$)|'
    r'www\.google\.[a-z]{2,}/maps|'
    r'goo\.gl/maps|'
    r'maps\.app\.goo\.gl)',
    caseSensitive: false,
  );

  static bool isValidHttpUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final uri = Uri.tryParse(value.trim());
    if (uri == null) return false;
    return (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static bool isValidGoogleMapsUrl(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    return googleMapsRegex.hasMatch(value.trim());
  }
}
