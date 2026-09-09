import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_voice_event.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';

/// A realtime spoken conversation with the assistant.
///
/// ## Why this is separate from `AiAudioRecorder`
///
/// A recorder produces one file and hands the microphone back. A session holds
/// the microphone for its whole life, never produces a message attachment, and
/// has states — `processing`, `speaking`, barge-in — that a recorder has no
/// concept of. Modelling both with one type would make every consumer ask
/// which mode it is in.
///
/// ## Why it is an interface with one mock implementation
///
/// The realtime transport is deliberately unresolved. `MockAiVoiceSession`
/// captures from the real microphone and mocks only the assistant, which is
/// what proves the client can carry a realtime session at all. When a real
/// transport arrives — WebRTC or otherwise — it is a second implementation of
/// this interface and neither the bloc nor the UI changes.
///
/// Implementations must never throw across this boundary: a failure surfaces
/// as [AiVoiceSessionStatus.error] on [status].
abstract interface class AiVoiceSession {
  /// Lifecycle transitions, in order. Broadcast.
  Stream<AiVoiceSessionStatus> get status;

  /// Live microphone loudness, normalised 0..1.
  ///
  /// The hot path — it ticks many times a second. A `Stream` here because the
  /// domain layer may not import Flutter; the presentation layer adapts it to
  /// a listenable so only the waveform rebuilds.
  Stream<double> get inputLevel;

  /// Semantic events — the assistant's UI requests and their resolutions.
  ///
  /// A third stream rather than a merge with [status] or [inputLevel]: these
  /// arrive once or twice a conversation while the level ticks dozens of times
  /// a second, and a consumer of one has no business filtering the other. See
  /// [AiVoiceEvent].
  ///
  /// This is the channel that makes live voice *bidirectional* in the same
  /// terms as chat: the payload it carries is an ordinary protocol document,
  /// and the answer that comes back through [submitInteraction] is an ordinary
  /// `AiUiInteraction`. Only the wire differs.
  Stream<AiVoiceEvent> get events;

  /// A localization key describing the failure, when [status] is
  /// [AiVoiceSessionStatus.error].
  String? get failureKey;

  /// Acquires the microphone and begins listening.
  Future<void> start();

  /// Stops sending microphone audio without ending the session.
  Future<void> setMuted({required bool muted});

  /// Ends the user's speaking turn and hands over to the assistant —
  /// `listening` → `processing`.
  ///
  /// The approved design drives the whole conversation from one button, and
  /// "I have finished talking, answer me" is the one transition the rest of
  /// this interface could not express: [interrupt] cuts the *assistant* off,
  /// [end] tears the session down, and neither says "my turn is over".
  ///
  /// Without it the turn could only end on the implementation's own
  /// silence/timeout, which is a session-internal heuristic the user cannot
  /// reach — so the button would have had nothing to call.
  ///
  /// Implementations must be idempotent and ignore the call outside
  /// [AiVoiceSessionStatus.listening]; a double tap is not an error. This
  /// only *requests* the transition — [status] remains the single source of
  /// truth for what state the session is actually in.
  Future<void> finishTurn();

  /// Cuts the assistant off mid-sentence and returns to listening.
  ///
  /// Called both by the user's stop button and by barge-in detection.
  Future<void> interrupt();

  /// Answers the card the assistant is waiting on.
  ///
  /// The same [AiUiInteraction] the chat transport would post as a turn — the
  /// interaction model, the lifecycle and the renderers are shared, and only
  /// the way the bytes leave the device is different.
  ///
  /// Implementations must be idempotent and ignore the call outside
  /// [AiVoiceSessionStatus.awaitingInteraction]: the ledger already refuses a
  /// second answer, and a late one arriving after the session moved on is not
  /// an error.
  Future<void> submitInteraction(AiUiInteraction interaction);

  /// Ends the session and releases everything.
  Future<void> end();

  /// Releases the session. Safe at any point, and safe to call twice.
  Future<void> dispose();
}
