import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';

/// Accumulates what the recogniser heard across one voice-note take.
///
/// ## Why a take needs an accumulator at all
///
/// The recogniser is built for phrases, not for a five-minute recording: it
/// settles on an answer and ends its own session after a pause, and each new
/// session reports its words from scratch. A take therefore spans several
/// sessions, and the naive `transcript = latest.text` would keep only the last
/// one — a recording where the user paused to think would arrive missing
/// everything said before the pause.
///
/// So finals are appended and the live partial is held separately. Replacing
/// the partial rather than appending it is what stops the growing text of a
/// single session from being counted many times.
///
/// Pure and allocation-light, in the same shape as `AudioLevelEnvelope`: the
/// whole thing is assertable with no microphone and no plugin.
final class VoiceNoteTranscript {
  final List<String> _settled = [];
  String _pending = '';

  /// Everything heard so far, settled segments first.
  String get text {
    final parts = [..._settled, _pending].where((p) => p.isNotEmpty);
    return parts.join(' ').trim();
  }

  /// Whether nothing has been heard.
  bool get isEmpty => text.isEmpty;

  /// Folds one reading in.
  ///
  /// A final settles the session and clears the partial; a partial replaces the
  /// previous partial, because the recogniser reports the whole phrase each
  /// time rather than the delta.
  void accept(AiSpeechTranscript value) {
    final words = value.text.trim();
    if (value.isFinal) {
      _pending = '';
      if (words.isNotEmpty) _settled.add(words);
      return;
    }
    _pending = words;
  }

  /// Settles whatever is pending, without a final from the recogniser.
  ///
  /// Called when a session ends on its own or is stopped by us. Without it, a
  /// session that was cut off mid-phrase would have its partial overwritten by
  /// the next session and the words would be lost.
  void commit() {
    if (_pending.isEmpty) return;
    _settled.add(_pending);
    _pending = '';
  }

  /// Forgets the take.
  void reset() {
    _settled.clear();
    _pending = '';
  }
}
