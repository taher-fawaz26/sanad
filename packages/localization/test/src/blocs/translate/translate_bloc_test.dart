import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';

class _MockStorage extends Mock implements Storage {}

void main() {
  late _MockStorage storage;

  setUp(() {
    storage = _MockStorage();
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((_) async {});
    when(() => storage.read(any())).thenReturn(null);
    HydratedBloc.storage = storage;
  });

  group('TranslateBloc defaults', () {
    test('is English with no persisted record', () {
      // The product default. It used to be Arabic in *both* the bloc and
      // EasyLocalization's startLocale (SAN-774).
      expect(TranslateBloc().state.language, AppLanguage.english);
      expect(TranslateBloc().state.languageCode, 'en');
    });

    test('the state default matches AppLanguage.defaultLanguage', () {
      // `languageCode` cannot reference the enum in a const default, so this
      // pins the literal to the single declared default.
      expect(const TranslateState().language, AppLanguage.defaultLanguage);
    });
  });

  group('TranslateBloc hydration', () {
    test('a persisted language beats the fallback constructor argument', () {
      when(() => storage.read(any())).thenReturn({'language_code': 'ar'});
      expect(TranslateBloc().state.language, AppLanguage.arabic);
      expect(
        // Spelled out even though it matches the default: the assertion is
        // that an explicit seed loses to a stored choice.
        // ignore: avoid_redundant_argument_values
        TranslateBloc(fallback: AppLanguage.english).state.language,
        AppLanguage.arabic,
        reason: 'a stored choice always wins over the seed',
      );
    });

    test('fallback applies only when there is no record', () {
      // This is the seam the legacy-store migration hands its value to.
      expect(
        TranslateBloc(fallback: AppLanguage.arabic).state.language,
        AppLanguage.arabic,
      );
    });

    test(
      'a malformed or unsupported persisted value falls back to English',
      () {
        for (final stored in <Map<String, dynamic>>[
          {'language_code': 'fr'},
          {'language_code': ''},
          <String, dynamic>{},
          {'language_code': 42},
        ]) {
          when(() => storage.read(any())).thenReturn(stored);
          expect(
            TranslateBloc().state.language,
            AppLanguage.english,
            reason: '$stored',
          );
        }
      },
    );

    test('toJson/fromJson round-trip', () {
      final bloc = TranslateBloc();
      final json = bloc.toJson(
        const TranslateState(language: AppLanguage.arabic),
      );
      expect(json, {'language_code': 'ar'});
      expect(bloc.fromJson(json!)!.language, AppLanguage.arabic);
    });
  });

  group('AppLanguageSelected', () {
    blocTest<TranslateBloc, TranslateState>(
      'switches to Arabic and persists',
      build: TranslateBloc.new,
      act: (bloc) => bloc.add(const AppLanguageSelected(AppLanguage.arabic)),
      expect: () => const [TranslateState(language: AppLanguage.arabic)],
      verify: (_) => verify(
        () => storage.write(any(), {'language_code': 'ar'}),
      ).called(1),
    );

    blocTest<TranslateBloc, TranslateState>(
      'switches back to English',
      build: () => TranslateBloc(fallback: AppLanguage.arabic),
      act: (bloc) => bloc.add(const AppLanguageSelected(AppLanguage.english)),
      // Named explicitly so the expected state reads unambiguously next to
      // the Arabic seed above it.
      // ignore: avoid_redundant_argument_values
      expect: () => const [TranslateState(language: AppLanguage.english)],
    );

    blocTest<TranslateBloc, TranslateState>(
      're-selecting the active language emits nothing',
      build: TranslateBloc.new,
      act: (bloc) => bloc.add(const AppLanguageSelected(AppLanguage.english)),
      expect: () => const <TranslateState>[],
    );
  });
}
