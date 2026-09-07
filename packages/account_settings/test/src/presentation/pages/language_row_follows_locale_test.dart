// Reproduces the EXACT composition AccountSettingsPage uses for the language
// row — BlocBuilder<TranslateBloc> → LanguagePreferencesSection, labelled from
// `translateState.language.labelKey` — rather than mounting the whole page
// (which needs sl<SessionManager>, AuthBloc and SecurityBloc).
//
// SAN-774: the row used to be labelled from `AccountSettingsState
// .preferredLanguage` (the *server's* value, defaulting to English when the
// profile had not loaded), so an Arabic UI could read "Language: English".
// The invariant under test is: current app locale == Account Settings
// language value, always.
//
// No EasyLocalization ancestor in this sandbox, so `.tr()` returns the raw
// key — labels are matched by key, per this repo's widget-test convention.
import 'package:account_settings/src/presentation/widgets/sections/language_preferences_section.dart';
import 'package:design_system/design_system.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

const _surfaceSize = Size(900, 1200);

void main() {
  setUp(() {
    final storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    HydratedBloc.storage = storage;
  });

  /// Mounts the row and returns the bloc driving it. The bloc is created here,
  /// inside the test body's zone — one built in `setUp` never flushes events
  /// under `testWidgets`' fake clock.
  Future<TranslateBloc> pump(
    WidgetTester tester, {
    required AppLanguage language,
  }) async {
    final bloc = TranslateBloc(fallback: language);
    addTearDown(bloc.close);

    await tester.binding.setSurfaceSize(_surfaceSize);
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: _surfaceSize,
        minTextAdapt: true,
        builder: (_, _) => MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: BlocProvider<TranslateBloc>.value(
              value: bloc,
              child: BlocBuilder<TranslateBloc, TranslateState>(
                builder: (context, translateState) =>
                    LanguagePreferencesSection(
                      selectedLanguageLabel: translateState.language.labelKey
                          .tr(),
                      onTap: () {},
                    ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return bloc;
  }

  testWidgets('shows Arabic when the app is running in Arabic', (tester) async {
    await pump(tester, language: AppLanguage.arabic);

    expect(find.text('app.arabic'), findsOneWidget);
    expect(
      find.text('app.english'),
      findsNothing,
      reason: 'the server default must not win over the active locale',
    );
  });

  testWidgets('shows English when the app is running in English', (
    tester,
  ) async {
    await pump(tester, language: AppLanguage.english);

    expect(find.text('app.english'), findsOneWidget);
    expect(find.text('app.arabic'), findsNothing);
  });

  testWidgets('follows a language change while the page is already open, '
      'with no navigation and no manual refresh', (tester) async {
    final bloc = await pump(tester, language: AppLanguage.english);
    expect(find.text('app.english'), findsOneWidget);

    bloc.add(const AppLanguageSelected(AppLanguage.arabic));
    await tester.pumpAndSettle();

    expect(find.text('app.arabic'), findsOneWidget);
    expect(find.text('app.english'), findsNothing);

    // And back, in place.
    bloc.add(const AppLanguageSelected(AppLanguage.english));
    await tester.pumpAndSettle();

    expect(find.text('app.english'), findsOneWidget);
  });
}
