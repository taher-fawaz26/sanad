import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network/network.dart';

class _MockStorage extends Mock implements Storage {}

/// One language switch must move the UI locale *and* the API language
/// together.
///
/// This is the SAN-774 regression at the architectural level: the app kept the
/// UI locale (EasyLocalization) and the API language (TranslateBloc) in two
/// separately-persisted stores synced by hand at three call sites, each with a
/// `mounted` early-return that could skip the second step. They could
/// therefore disagree — producing an Arabic UI whose backend-localized content
/// (`statistics[].name`, `branch.city.name`) came back in English.
void main() {
  setUp(() {
    final storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  testWidgets('one dispatch moves the UI locale and the language headers', (
    tester,
  ) async {
    // Built inside the test body: a bloc constructed in `setUp` sits outside
    // testWidgets' fake-async zone and its events never flush.
    final bloc = TranslateBloc();
    addTearDown(bloc.close);

    // Exactly the production wiring from `configureDependencies`.
    final interceptor = AcceptLanguageInterceptor(
      resolveLanguageCode: () => bloc.state.languageCode,
    );

    /// The headers the app would send right now. Driven directly rather than
    /// through a real Dio request: `testWidgets` runs on a fake clock, so an
    /// awaited HTTP round-trip never completes.
    Map<String, dynamic> headersNow() {
      final options = RequestOptions(path: '/service-provider/statistics');
      interceptor.onRequest(options, RequestInterceptorHandler());
      return options.headers;
    }

    final applied = <Locale>[];
    var uiLocale = const Locale('en', 'US');

    await tester.pumpWidget(
      BlocProvider<TranslateBloc>.value(
        value: bloc,
        child: AppLocaleSync(
          currentLocale: (_) => uiLocale,
          applyLocale: (_, locale) async {
            applied.add(locale);
            uiLocale = locale;
          },
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Baseline: English UI, English headers, and no reconcile needed.
    expect(applied, isEmpty);
    expect(headersNow()['x-lang'], 'en');

    // A single dispatch — no `setLocale` at the call site.
    bloc.add(const AppLanguageSelected(AppLanguage.arabic));
    await tester.pumpAndSettle();

    expect(applied, [const Locale('ar', 'AR')], reason: 'UI locale followed');
    expect(
      headersNow()['x-lang'],
      'ar',
      reason:
          'the backend localizes statistics[].name and branch.city.name '
          'from this header, so it must follow the UI',
    );
    expect(headersNow()['Accept-Language'], 'ar');

    // And back again.
    bloc.add(const AppLanguageSelected(AppLanguage.english));
    await tester.pumpAndSettle();

    expect(uiLocale, const Locale('en', 'US'));
    expect(headersNow()['x-lang'], 'en');
  });
}
