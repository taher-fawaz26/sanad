import 'package:localization/src/blocs/translate/translate_bloc.dart';
import 'package:localization/src/locale/app_language.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One-time migration off `EasyLocalization`'s own locale storage.
///
/// The app used to persist the language twice — `EasyLocalization` in
/// `SharedPreferences['locale']` and [TranslateBloc] in hydrated storage — and
/// the two could disagree (SAN-774). [TranslateBloc] is now the only store, but
/// the legacy key has to be dealt with rather than merely ignored:
///
/// `EasyLocalization.ensureInitialized()` reads `'locale'` into a **static**
/// `_savedLocale` *unconditionally* — `saveLocale: false` only suppresses
/// writes, not that read. Its controller then picks `startLocale` **only when
/// `_savedLocale == null`**, and otherwise (saved value present but
/// `saveLocale: false`) falls through to the **device locale**. So a leftover
/// key would silently override the user's real preference with whatever
/// language their phone is in.
///
/// Hence [takeIfAny] must run **before** `ensureInitialized()`. Removing the
/// key afterwards is useless — the static is already latched.
abstract final class LegacyLocalePreference {
  /// `EasyLocalization`'s own preferences key.
  static const String storageKey = 'locale';

  /// Reads and removes the legacy preference, returning the language it named.
  ///
  /// Returns `null` when there is nothing to migrate or the stored value names
  /// no supported language. Idempotent — a second call finds nothing.
  ///
  /// Must be awaited **before** `EasyLocalization.ensureInitialized()`.
  static Future<AppLanguage?> takeIfAny() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null) return null;
    await preferences.remove(storageKey);
    // Stored by `Locale.toString()`, i.e. `ar_AR` — `tryFromCode` takes the
    // primary subtag, so the BCP-47 form is accepted too.
    return AppLanguage.tryFromCode(raw);
  }

  /// Makes [language] the bloc's language when a hydrated record disagrees
  /// with it.
  ///
  /// Only the disagreement case needs work, and only in one direction: the
  /// legacy value is what the user actually *saw* (every old call site applied
  /// the UI locale before the bloc event, and could then skip the event), so it
  /// is at least as fresh as the bloc's and wins.
  ///
  /// Nothing is needed when the two already agree: `HydratedBloc.hydrate()`
  /// writes whatever state it resolves — including a seeded fallback — so a
  /// user who had only the legacy key already has it persisted by the time the
  /// bloc is constructed.
  static void adopt(TranslateBloc bloc, AppLanguage language) {
    if (bloc.state.language == language) return;
    bloc.add(AppLanguageSelected(language));
  }
}
