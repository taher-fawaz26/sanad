/// Supported account preferred languages from `GET/PATCH account-settings`.
enum PreferredLanguage {
  en,
  ar
  ;

  /// API wire value (`en`, `ar`).
  String toApi() => name;

  static PreferredLanguage fromApi(String value) {
    return switch (value) {
      'ar' => PreferredLanguage.ar,
      _ => PreferredLanguage.en,
    };
  }
}
