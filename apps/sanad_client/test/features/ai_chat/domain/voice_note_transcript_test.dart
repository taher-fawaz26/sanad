import 'package:flutter_test/flutter_test.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/usecases/voice_note_transcript.dart';

AiSpeechTranscript partial(String text) =>
    AiSpeechTranscript(text: text, isFinal: false);

AiSpeechTranscript settled(String text) =>
    AiSpeechTranscript(text: text, isFinal: true);

void main() {
  late VoiceNoteTranscript transcript;

  setUp(() => transcript = VoiceNoteTranscript());

  group('within one recognition session', () {
    test('starts empty', () {
      expect(transcript.text, '');
      expect(transcript.isEmpty, isTrue);
    });

    test('a partial replaces the previous partial', () {
      // The recogniser reports the whole phrase each time, not the delta, so
      // appending would count the growing text over and over.
      transcript
        ..accept(partial('book'))
        ..accept(partial('book me'))
        ..accept(partial('book me a plumber'));

      expect(transcript.text, 'book me a plumber');
    });

    test('a final supersedes the partials it followed', () {
      transcript
        ..accept(partial('book me a'))
        ..accept(settled('book me a plumber'));

      expect(transcript.text, 'book me a plumber');
    });
  });

  group('across the sessions one take spans', () {
    test('finals accumulate rather than replace', () {
      // The recogniser settles after its own pause, so a five-minute take
      // outlives many of its sessions. Keeping only the last one is how a
      // recording where the user paused to think loses its first half.
      transcript
        ..accept(settled('book me a plumber'))
        ..accept(partial('for tomorrow'))
        ..accept(settled('for tomorrow morning'));

      expect(transcript.text, 'book me a plumber for tomorrow morning');
    });

    test('a session cut off mid-phrase keeps its words once committed', () {
      transcript
        ..accept(settled('book me a plumber'))
        ..accept(partial('for tomorrow'))
        // The session ended without a final — we stopped it, or the platform
        // did. Without the commit, the next session's partial would overwrite
        // these words.
        ..commit()
        ..accept(partial('please'));

      expect(transcript.text, 'book me a plumber for tomorrow please');
    });

    test('committing twice does not duplicate', () {
      transcript
        ..accept(partial('hello'))
        ..commit()
        ..commit();

      expect(transcript.text, 'hello');
    });

    test('committing nothing is a no-op', () {
      transcript
        ..accept(settled('hello'))
        ..commit();

      expect(transcript.text, 'hello');
    });
  });

  group('the shape of what it keeps', () {
    test('blank readings contribute nothing', () {
      // A recogniser that heard nothing reports an empty string rather than
      // staying silent; joining those in would leave stray spaces.
      transcript
        ..accept(settled('hello'))
        ..accept(settled('   '))
        ..accept(settled('there'));

      expect(transcript.text, 'hello there');
    });

    test('surrounding whitespace never survives', () {
      transcript.accept(partial('  hello  '));

      expect(transcript.text, 'hello');
    });

    test('reset forgets the take', () {
      transcript
        ..accept(settled('hello'))
        ..accept(partial('there'))
        ..reset();

      expect(transcript.text, '');
      expect(transcript.isEmpty, isTrue);
    });
  });
}
