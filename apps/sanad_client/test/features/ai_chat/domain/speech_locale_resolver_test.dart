import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/speech_locale_resolver.dart';

/// Choosing which language to dictate in.
///
/// The device is the authority on what it can recognise, so every case here
/// asks the resolver to pick from a list the device supplied rather than
/// asserting a tag and hoping. `null` is a real answer — it means "let the
/// device decide", which is what keeps an unavailable language from turning
/// into a dead button.
void main() {
  group('picks the preferred region', () {
    test('Arabic prefers the UAE, matching AppIntlLocale', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'ar',
          available: ['en-US', 'ar-SA', 'ar-AE', 'ar-EG'],
        ),
        'ar-AE',
      );
    });

    test('English prefers US', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'en',
          available: ['en-GB', 'en-US', 'ar-AE'],
        ),
        'en-US',
      );
    });

    test('it falls to the next preference when the first is missing', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'ar',
          available: ['ar-SA', 'en-US'],
        ),
        'ar-SA',
      );
    });
  });

  group('tolerates however the platform spells it', () {
    test('Android underscores match', () {
      // Android reports `ar_AE`, iOS reports `ar-AE`.
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'ar',
          available: ['ar_AE'],
        ),
        'ar_AE',
        reason: "must hand back the device's own spelling, not a re-cased one",
      );
    });

    test('case does not matter', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'EN',
          available: ['EN_us'],
        ),
        'EN_us',
      );
    });

    test('a full app tag is accepted, not just a bare code', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'en-US',
          available: ['en-GB'],
        ),
        'en-GB',
      );
    });
  });

  group('falls back within the language', () {
    test('an unlisted region still counts as the right language', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'en',
          available: ['en-IN', 'fr-FR'],
        ),
        'en-IN',
      );
    });

    test('a bare language tag counts', () {
      expect(
        SpeechLocaleResolver.resolve(languageCode: 'ar', available: ['ar']),
        'ar',
      );
    });

    test('a language that merely starts with the same letters does not', () {
      // `en` must not match `eng-XX` by prefix — only a whole subtag counts.
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'en',
          available: ['english-XX'],
        ),
        isNull,
      );
    });
  });

  group('gives up gracefully', () {
    test('a language the device cannot recognise returns null', () {
      expect(
        SpeechLocaleResolver.resolve(
          languageCode: 'ar',
          available: ['en-US', 'fr-FR'],
        ),
        isNull,
        reason: 'null means "let the device decide", not "fail"',
      );
    });

    test('an empty device list returns null', () {
      expect(
        SpeechLocaleResolver.resolve(languageCode: 'ar', available: const []),
        isNull,
      );
    });

    test('junk input does not explode', () {
      for (final code in ['', '   ', '-', '_']) {
        expect(
          SpeechLocaleResolver.resolve(
            languageCode: code,
            available: ['en-US'],
          ),
          isNull,
          reason: 'code "$code" should resolve to nothing',
        );
      }
    });

    test('both supported app languages are covered', () {
      // Guards against adding a language to `AppLanguage` and forgetting the
      // recognition preferences that go with it.
      expect(SpeechLocaleResolver.preferences.keys, containsAll(['en', 'ar']));
    });
  });
}
