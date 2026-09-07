import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

/// What [AppLocaleSync] did, and the bloc that drives it.
class _Harness {
  _Harness(this.bloc, this.applied);

  final TranslateBloc bloc;
  final List<Locale> applied;
}

void main() {
  setUp(() {
    final storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  /// Pumps [AppLocaleSync] with both seams stubbed — the real ones need a live
  /// `EasyLocalization` ancestor, which `ensureInitialized()` cannot provide
  /// in the test sandbox.
  ///
  /// The bloc is built *inside* the test body on purpose: a bloc constructed
  /// in `setUp` lives outside `testWidgets`' fake-async zone, so `pump` never
  /// flushes its event stream and no state ever arrives.
  Future<_Harness> pump(
    WidgetTester tester, {
    required Locale reported,
  }) async {
    final bloc = TranslateBloc();
    addTearDown(bloc.close);

    final applied = <Locale>[];
    var current = reported;

    await tester.pumpWidget(
      BlocProvider<TranslateBloc>.value(
        value: bloc,
        child: AppLocaleSync(
          currentLocale: (_) => current,
          applyLocale: (_, locale) async {
            applied.add(locale);
            current = locale;
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return _Harness(bloc, applied);
  }

  testWidgets('does not touch the locale when it already agrees', (
    tester,
  ) async {
    // The bootstrap's startLocale normally already matches, so the initial
    // reconcile must be a no-op — otherwise every launch would flash.
    final harness = await pump(tester, reported: const Locale('en', 'US'));
    expect(harness.applied, isEmpty);
  });

  testWidgets('reconciles a disagreement on the first frame', (tester) async {
    // The self-heal path: EasyLocalization is showing Arabic while the single
    // source of truth says English — SAN-774's exact desync.
    final harness = await pump(tester, reported: const Locale('ar', 'AR'));
    expect(harness.applied, [const Locale('en', 'US')]);
  });

  testWidgets('applies the language the bloc switches to, both ways', (
    tester,
  ) async {
    final harness = await pump(tester, reported: const Locale('en', 'US'));

    harness.bloc.add(const AppLanguageSelected(AppLanguage.arabic));
    await tester.pumpAndSettle();
    expect(harness.applied, [const Locale('ar', 'AR')]);

    harness.bloc.add(const AppLanguageSelected(AppLanguage.english));
    await tester.pumpAndSettle();
    expect(harness.applied, [
      const Locale('ar', 'AR'),
      const Locale('en', 'US'),
    ]);
  });

  testWidgets('re-selecting the active language applies nothing', (
    tester,
  ) async {
    final harness = await pump(tester, reported: const Locale('en', 'US'));

    harness.bloc
      ..add(const AppLanguageSelected(AppLanguage.english))
      ..add(const AppLanguageSelected(AppLanguage.english));
    await tester.pumpAndSettle();

    expect(harness.applied, isEmpty);
  });
}
