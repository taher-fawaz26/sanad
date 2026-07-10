// Architectural interface — single-method by design for use-case isolation.
// ignore: one_member_abstracts
abstract class LocaleChangeHandler {
  Future<void> onAppLocaleChanged();
}
