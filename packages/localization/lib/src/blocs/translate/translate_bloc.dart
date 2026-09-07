import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/src/locale/app_language.dart';

part 'translate_event.dart';
part 'translate_state.dart';

/// Single source of truth for the app's language.
///
/// Hydrated, so the user's choice survives a restart — and it is the *only*
/// store: `EasyLocalization` is configured with `saveLocale: false` and is
/// driven from this bloc by `AppLocaleSync`, so a persisted UI locale can never
/// disagree with the language the API headers and language-keyed caches use
/// (SAN-774). Change the language only via `context.setAppLanguage`.
class TranslateBloc extends HydratedBloc<TranslateEvent, TranslateState> {
  /// [fallback] is used only when there is no persisted record at all — a
  /// hydrated record always wins. That makes it the seam the one-time
  /// migration off `EasyLocalization`'s own storage hands the legacy value to
  /// (see `LegacyLocalePreference`); everywhere else it is the product default.
  TranslateBloc({AppLanguage fallback = AppLanguage.defaultLanguage})
    : super(TranslateState(language: fallback)) {
    on<AppLanguageSelected>(_onLanguageSelected);
  }

  void _onLanguageSelected(
    AppLanguageSelected event,
    Emitter<TranslateState> emit,
  ) {
    // Explicit no-op guard: `Bloc.emit` only drops an equal state once it has
    // emitted at least once, so without this, re-selecting the active language
    // on a freshly built bloc would emit and re-persist for nothing.
    if (event.language == state.language) return;
    emit(TranslateState(language: event.language));
  }

  @override
  TranslateState? fromJson(Map<String, dynamic> json) =>
      TranslateState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(TranslateState state) => state.toMap();
}
