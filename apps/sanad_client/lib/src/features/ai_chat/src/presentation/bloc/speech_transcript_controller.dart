import 'package:flutter/foundation.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';

/// Carries the words being recognised right now.
///
/// The same family as `ActiveStreamController` and `VoiceLevelController`, and
/// it exists for the same reason. A recogniser emits a partial result on
/// almost every word. Routing those through `AiComposerState` would emit a new
/// state — and therefore a new attachment list — several times a second,
/// rebuilding the composer, every attachment tile, and the message list above
/// it. So partials live here and the bloc emits **nothing** for them.
///
/// What the bloc *does* own is the lifecycle: whether dictation is starting,
/// listening, finalising or failed is business state and stays in
/// `AiComposerState`. This is only the text in flight.
class SpeechTranscriptController extends ValueNotifier<AiSpeechTranscript> {
  /// Starts with nothing recognised.
  SpeechTranscriptController() : super(AiSpeechTranscript.empty);

  /// Returns to silence, for when dictation ends or is thrown away.
  void reset() => value = AiSpeechTranscript.empty;
}
