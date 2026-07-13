import 'package:localization/src/blocs/translate/translate_bloc.dart';

/// Resolves the current API locale code from [TranslateBloc] on each call.
/// Used by `AcceptLanguageInterceptor` so headers always reflect the live
/// locale.
class ApiLocaleResolver {
  ApiLocaleResolver(this._bloc);

  final TranslateBloc _bloc;

  String get currentLanguageCode => _bloc.state.languageCode;
}
