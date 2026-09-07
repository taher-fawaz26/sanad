import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/speech/speech_to_text_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';

/// The boundary where the platform's vocabulary stops.
///
/// `SpeechRecognizer`'s error identifiers are the platform's, not ours, and
/// they must not reach a bloc or a screen. This pins the whole table so a
/// string that changes meaning shows up here rather than as an unhelpful
/// message in front of a user.
void main() {
  group('permission errors carry the permanence through', () {
    test('a refusal that can be asked again', () {
      expect(
        SpeechToTextRecognizer.mapError('error_permission', permanent: false),
        AiSpeechFailure.permissionDenied,
      );
    });

    test('a refusal that cannot', () {
      // Only this one may offer the settings path, so getting it wrong either
      // strands the user or nags them pointlessly.
      expect(
        SpeechToTextRecognizer.mapError('error_permission', permanent: true),
        AiSpeechFailure.permissionPermanentlyDenied,
      );
    });
  });

  group('the rest of the table', () {
    const cases = <String, AiSpeechFailure>{
      'error_no_match': AiSpeechFailure.noMatch,
      'error_speech_timeout': AiSpeechFailure.timeout,
      'error_no_speech_timeout': AiSpeechFailure.timeout,
      'error_network': AiSpeechFailure.network,
      'error_network_timeout': AiSpeechFailure.network,
      'error_language_not_supported': AiSpeechFailure.unavailable,
      'error_language_unavailable': AiSpeechFailure.unavailable,
      'error_busy': AiSpeechFailure.unavailable,
      'error_client': AiSpeechFailure.unavailable,
    };

    for (final entry in cases.entries) {
      test('${entry.key} → ${entry.value.name}', () {
        expect(
          SpeechToTextRecognizer.mapError(entry.key, permanent: false),
          entry.value,
        );
      });
    }
  });

  group('anything unrecognised is still handled', () {
    test('an unknown identifier falls back rather than throwing', () {
      expect(
        SpeechToTextRecognizer.mapError(
          'error_from_the_future',
          permanent: false,
        ),
        AiSpeechFailure.platform,
      );
    });

    test('an empty identifier falls back', () {
      expect(
        SpeechToTextRecognizer.mapError('', permanent: false),
        AiSpeechFailure.platform,
      );
    });

    test('every mapping returns something', () {
      // The switch is not exhaustive over strings, so the wildcard arm is the
      // only thing standing between a new platform error and a crash.
      for (final id in ['x', 'ERROR_NO_MATCH', 'error_ ', '123']) {
        expect(
          () => SpeechToTextRecognizer.mapError(id, permanent: true),
          returnsNormally,
        );
      }
    });
  });

  group('the listen configuration is tuned for dictation', () {
    test('a phrase is given time to be thought about', () {
      // The plugin's default pause is tuned for one-word commands; a person
      // composing a message stops to think mid-sentence.
      expect(
        SpeechToTextRecognizer.pauseDuration,
        greaterThanOrEqualTo(const Duration(seconds: 3)),
      );
    });

    test('a dictation can run long enough to be useful', () {
      expect(
        SpeechToTextRecognizer.maxListenDuration,
        greaterThan(SpeechToTextRecognizer.pauseDuration),
      );
    });
  });
}
