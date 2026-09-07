import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/src/blocs/translate/translate_bloc.dart';

/// Applies [TranslateBloc]'s language to `EasyLocalization` — the **only**
/// place in the app that calls `setLocale`.
///
/// [TranslateBloc] owns the language; `EasyLocalization` renders it. Mount this
/// inside both the `TranslateBloc` provider and the `EasyLocalization` widget,
/// above the router. `MaterialApp.locale` keeps reading `context.locale`:
/// driving it from the bloc instead would be subtly wrong, because
/// `EasyLocalization`'s delegate hands out whichever translations its
/// controller last loaded regardless of the requested locale, so `.tr()` would
/// resolve against one language while `Localizations.localeOf` reported the
/// other. The controller has to be moved, and `setLocale` is what moves it.
///
/// There is no rebuild loop: `setLocale` early-returns on an unchanged locale,
/// and this widget subscribes to [TranslateBloc] only — never to
/// `context.locale` — so the rebuild it triggers cannot re-enter the listener.
class AppLocaleSync extends StatefulWidget {
  const AppLocaleSync({
    required this.child,
    this.applyLocale,
    this.currentLocale,
    super.key,
  });

  final Widget child;

  /// Seam for tests. Defaults to `context.setLocale`.
  ///
  /// Widget tests in this repo deliberately run without an `EasyLocalization`
  /// ancestor (`EasyLocalization.ensureInitialized()` hangs in the test
  /// sandbox), so the listener logic is only testable through injectable
  /// read/apply steps. Both seams must be overridden together — reading
  /// `context.locale` also requires that ancestor.
  final Future<void> Function(BuildContext context, Locale locale)? applyLocale;

  /// Seam for tests. Defaults to `context.locale`.
  final Locale Function(BuildContext context)? currentLocale;

  @override
  State<AppLocaleSync> createState() => _AppLocaleSyncState();
}

class _AppLocaleSyncState extends State<AppLocaleSync> {
  @override
  void initState() {
    super.initState();
    // Self-heal on first frame. Normally the bootstrap's `startLocale` already
    // matches the bloc, so this is a no-op and there is no first-frame flash of
    // the wrong language — but it is the safety net for any path that defeats
    // `startLocale` (a leftover locale in EasyLocalization's own storage, a
    // rollback/reinstall). Deferred to a post-frame callback because
    // `dependOnInheritedWidgetOfExactType` — which both `context.locale` and
    // `setLocale` need — is not allowed during `initState`.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _apply(context.read<TranslateBloc>().state);
    });
  }

  void _apply(TranslateState state) {
    if (!mounted) return;
    final read = widget.currentLocale ?? _readLocale;
    if (read(context).languageCode == state.languageCode) return;
    final apply = widget.applyLocale ?? _setLocale;
    apply(context, state.language.locale).ignore();
  }

  static Locale _readLocale(BuildContext context) => context.locale;

  static Future<void> _setLocale(BuildContext context, Locale locale) =>
      context.setLocale(locale);

  @override
  Widget build(BuildContext context) {
    return BlocListener<TranslateBloc, TranslateState>(
      listenWhen: (previous, current) => previous.language != current.language,
      listener: (context, state) => _apply(state),
      child: widget.child,
    );
  }
}
