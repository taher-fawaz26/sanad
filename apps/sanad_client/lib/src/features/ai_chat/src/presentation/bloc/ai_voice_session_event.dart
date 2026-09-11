part of 'ai_voice_session_bloc.dart';

/// Everything the voice screen asks the session to do.
sealed class AiVoiceSessionEvent extends Equatable {
  /// Const so subclasses can be const.
  const AiVoiceSessionEvent();

  @override
  List<Object?> get props => [];
}

/// The user pressed start.
final class AiVoiceSessionStartRequested extends AiVoiceSessionEvent {
  /// Creates the start.
  const AiVoiceSessionStartRequested();
}

/// The user toggled the microphone.
final class AiVoiceSessionMuteToggled extends AiVoiceSessionEvent {
  /// Creates the toggle.
  const AiVoiceSessionMuteToggled();
}

/// The user finished speaking and wants the assistant to answer —
/// `listening` → `processing`.
///
/// Distinct from [AiVoiceSessionInterrupted]: that one stops the *assistant*,
/// this one ends the *user's* turn. The approved design drives both from the
/// same button, and which of the two a tap means is decided from the session
/// status, never from state kept in the widget.
final class AiVoiceSessionTurnFinished extends AiVoiceSessionEvent {
  /// Creates the end-of-turn.
  const AiVoiceSessionTurnFinished();
}

/// The user cut the assistant off mid-reply.
final class AiVoiceSessionInterrupted extends AiVoiceSessionEvent {
  /// Creates the interruption.
  const AiVoiceSessionInterrupted();
}

/// The user ended the session.
final class AiVoiceSessionEndRequested extends AiVoiceSessionEvent {
  /// Creates the end.
  const AiVoiceSessionEndRequested();
}

/// The user asked to leave the voice screen entirely (A-05).
///
/// Ends the session through the same teardown as [AiVoiceSessionEndRequested]
/// — there is only ever one way down — and additionally records that the user
/// is *leaving*, which is what lets the route owner pop. Backgrounding also
/// ends the session but must not close the screen, so the two cannot share an
/// event.
final class AiVoiceSessionCloseRequested extends AiVoiceSessionEvent {
  /// Creates the close request.
  const AiVoiceSessionCloseRequested();
}

/// The app went to the background.
///
/// Deliberately not an audio-session interruption: that is another app taking
/// the audio path and arrives on `AudioSessionManager.events`, whereas this is
/// the OS putting the whole app behind something else. A live voice session
/// cannot meaningfully continue there — Android stops delivering microphone
/// data to a backgrounded app without a foreground service — so it ends
/// cleanly rather than lingering with the microphone held.
final class AiVoiceSessionBackgrounded extends AiVoiceSessionEvent {
  /// Creates the notification.
  const AiVoiceSessionBackgrounded();
}

/// The user accepted the offer to open system settings.
final class AiVoiceSessionSettingsRequested extends AiVoiceSessionEvent {
  /// Creates the request.
  const AiVoiceSessionSettingsRequested();
}

/// The user answered the card the assistant is waiting on.
///
/// Carries the same `AiUiInteraction` a chat card produces — the interaction
/// model, the ledger and the renderers are shared, and only the transport that
/// carries it differs.
final class AiVoiceSessionInteractionSubmitted extends AiVoiceSessionEvent {
  /// Creates a submission carrying [interaction].
  const AiVoiceSessionInteractionSubmitted(this.interaction);

  /// The answer, already accepted by the ledger.
  final AiUiInteraction interaction;

  @override
  List<Object?> get props => [interaction];
}

/// One semantic event off the session's own stream, re-entered through the
/// bloc so every state change goes through a single ordered queue — the same
/// discipline `AiChatBloc` applies to transport frames.
final class AiVoiceSessionEventReceived extends AiVoiceSessionEvent {
  /// Creates a wrapper around a session [event].
  const AiVoiceSessionEventReceived(this.event);

  /// The undecoded semantic event.
  final AiVoiceEvent event;

  @override
  List<Object?> get props => [event];
}

/// The session moved. Raised from its own stream, not by the UI, so every
/// transition travels one ordered queue.
final class AiVoiceSessionStatusChanged extends AiVoiceSessionEvent {
  /// Creates the transition.
  const AiVoiceSessionStatusChanged(this.status);

  /// Where the session is now.
  final AiVoiceSessionStatus status;

  @override
  List<Object?> get props => [status];
}
