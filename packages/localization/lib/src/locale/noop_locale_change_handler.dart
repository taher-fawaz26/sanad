import 'package:localization/src/locale/locale_change_handler.dart';

class NoopLocaleChangeHandler implements LocaleChangeHandler {
  @override
  Future<void> onAppLocaleChanged() async {}
}
