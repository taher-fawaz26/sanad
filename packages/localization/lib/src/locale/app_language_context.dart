import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/src/blocs/translate/translate_bloc.dart';
import 'package:localization/src/locale/app_language.dart';

/// The one way to read and change the app's language from the UI.
extension AppLanguageContext on BuildContext {
  /// Switches the app language.
  ///
  /// Dispatch-only and synchronous: it moves the single source of truth
  /// ([TranslateBloc]) and `AppLocaleSync` applies the locale to
  /// `EasyLocalization` in response. Call sites must never call
  /// `setLocale` themselves — the previous two-step
  /// `await setLocale(...)` + `if (!mounted) return;` + dispatch pattern had a
  /// window where the UI locale changed but the API language did not, and
  /// because the two were persisted separately that desync survived a restart
  /// (SAN-774).
  void setAppLanguage(AppLanguage language) =>
      read<TranslateBloc>().add(AppLanguageSelected(language));

  /// The active app language, read once (not reactive).
  ///
  /// Use `BlocBuilder<TranslateBloc, TranslateState>` when the widget must
  /// rebuild on a change.
  AppLanguage get appLanguage => read<TranslateBloc>().state.language;
}
