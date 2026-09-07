import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:localization/localization.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockStorage extends Mock implements Storage {}

void main() {
  late _MockStorage storage;
  late Map<String, dynamic> written;

  setUp(() {
    written = {};
    storage = _MockStorage();
    when(() => storage.read(any())).thenReturn(null);
    when(() => storage.write(any(), any<dynamic>())).thenAnswer((
      invocation,
    ) async {
      written[invocation.positionalArguments[0] as String] =
          invocation.positionalArguments[1];
    });
    HydratedBloc.storage = storage;
  });

  Future<String?> legacyValue() async =>
      (await SharedPreferences.getInstance()).getString(
        LegacyLocalePreference.storageKey,
      );

  group('takeIfAny', () {
    test(
      'returns null and writes nothing when there is no legacy key',
      () async {
        SharedPreferences.setMockInitialValues({});
        expect(await LegacyLocalePreference.takeIfAny(), isNull);
      },
    );

    test('reads Locale.toString() form and removes the key', () async {
      SharedPreferences.setMockInitialValues({
        LegacyLocalePreference.storageKey: 'ar_AR',
      });
      expect(await LegacyLocalePreference.takeIfAny(), AppLanguage.arabic);
      expect(
        await legacyValue(),
        isNull,
        reason:
            'a leftover key makes EasyLocalization fall back to the '
            'DEVICE locale under saveLocale: false',
      );
    });

    test('is idempotent — a second call finds nothing', () async {
      SharedPreferences.setMockInitialValues({
        LegacyLocalePreference.storageKey: 'en_US',
      });
      expect(await LegacyLocalePreference.takeIfAny(), AppLanguage.english);
      expect(await LegacyLocalePreference.takeIfAny(), isNull);
    });

    test('accepts BCP-47 and bare codes', () async {
      for (final entry in {
        'ar': AppLanguage.arabic,
        'ar-AR': AppLanguage.arabic,
        'en-US': AppLanguage.english,
        'en': AppLanguage.english,
      }.entries) {
        SharedPreferences.setMockInitialValues({
          LegacyLocalePreference.storageKey: entry.key,
        });
        expect(
          await LegacyLocalePreference.takeIfAny(),
          entry.value,
          reason: entry.key,
        );
      }
    });

    test('an unsupported stored value migrates nothing, but is still '
        'removed', () async {
      SharedPreferences.setMockInitialValues({
        LegacyLocalePreference.storageKey: 'fr_FR',
      });
      expect(await LegacyLocalePreference.takeIfAny(), isNull);
      expect(await legacyValue(), isNull);
    });
  });

  group('adopt', () {
    test('corrects a disagreeing bloc and persists the correction', () async {
      // The two stores disagreed: EasyLocalization said Arabic (what the user
      // actually saw) while the bloc said English (what the API headers used).
      // The visible one wins.
      when(() => storage.read(any())).thenReturn({'language_code': 'en'});
      final bloc = TranslateBloc();
      expect(bloc.state.language, AppLanguage.english);

      LegacyLocalePreference.adopt(bloc, AppLanguage.arabic);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.language, AppLanguage.arabic);
      expect(written[bloc.storageToken], {'language_code': 'ar'});
    });

    test('a legacy-only user has the seeded language already persisted, so '
        'it survives the next launch', () {
      // HydratedBloc.hydrate() writes whatever state it resolves, seeded
      // fallback included — so no explicit flush is needed and the migrated
      // language cannot evaporate.
      final bloc = TranslateBloc(fallback: AppLanguage.arabic);

      expect(bloc.state.language, AppLanguage.arabic);
      expect(written[bloc.storageToken], {'language_code': 'ar'});

      LegacyLocalePreference.adopt(bloc, AppLanguage.arabic);
      expect(bloc.state.language, AppLanguage.arabic);
    });
  });
}
