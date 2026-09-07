// SAN-774: the dashboard cards are backend-owned copy.
//
// `GET /service-provider/statistics` returns `statistics[].name` localized
// from the request language, and the app renders it verbatim (there are
// deliberately no `home.stat_*` keys — client-side labels would duplicate
// backend copy). So a language switch has to re-fetch, otherwise the cards
// keep the previous language's names.
//
// This covers the wiring at `home_page.dart`'s BlocListener<TranslateBloc>,
// which had no widget-level test. The listener is reproduced here rather than
// mounting ProviderHomePage, which needs the whole DI graph.
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

void main() {
  setUp(() {
    final storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  testWidgets('a language change fires exactly one refresh per switch, and '
      'none for a no-op re-selection', (tester) async {
    final bloc = TranslateBloc();
    addTearDown(bloc.close);

    final refreshedFor = <String>[];

    await tester.pumpWidget(
      BlocProvider<TranslateBloc>.value(
        value: bloc,
        child: BlocListener<TranslateBloc, TranslateState>(
          listenWhen: (previous, current) =>
              previous.languageCode != current.languageCode,
          listener: (context, state) => refreshedFor.add(state.languageCode),
          child: const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(refreshedFor, isEmpty, reason: 'mounting must not refetch');

    bloc.add(const AppLanguageSelected(AppLanguage.arabic));
    await tester.pumpAndSettle();
    expect(refreshedFor, ['ar']);

    // Re-selecting the active language must not spend a request.
    bloc.add(const AppLanguageSelected(AppLanguage.arabic));
    await tester.pumpAndSettle();
    expect(refreshedFor, ['ar']);

    bloc.add(const AppLanguageSelected(AppLanguage.english));
    await tester.pumpAndSettle();
    expect(refreshedFor, ['ar', 'en']);
  });
}
