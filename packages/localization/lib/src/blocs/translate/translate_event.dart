part of 'translate_bloc.dart';

sealed class TranslateEvent extends Equatable {
  const TranslateEvent();

  @override
  List<Object> get props => [];
}

/// The user chose an app language.
///
/// The only way to change the app's language. Replaces the former
/// `TrArabicEvent`/`TrEnglishEvent` pair: one parameterized, const-constructible
/// event means call sites never branch on the language to pick an event, and
/// adding a third language does not add a third event.
final class AppLanguageSelected extends TranslateEvent {
  const AppLanguageSelected(this.language);

  final AppLanguage language;

  @override
  List<Object> get props => [language];
}
