part of 'translate_bloc.dart';

/// The app's current language — the single source of truth.
///
/// Holds a typed [AppLanguage] rather than a raw string so an unsupported
/// value cannot exist in the first place; [languageCode] stays available for
/// the API header and language-keyed cache keys.
class TranslateState extends Equatable {
  const TranslateState({this.language = AppLanguage.defaultLanguage});

  /// Restores a persisted state, falling back to the product default for a
  /// missing, malformed, or no-longer-supported stored value.
  factory TranslateState.fromMap(Map<String, dynamic> map) => TranslateState(
    language: AppLanguage.fromCode(map[_storageKey] as String?),
  );

  static const String _storageKey = 'language_code';

  /// The active language.
  final AppLanguage language;

  /// The API language code (`ar` / `en`).
  String get languageCode => language.code;

  @override
  List<Object> get props => [language];

  Map<String, dynamic> toMap() => {_storageKey: languageCode};
}
