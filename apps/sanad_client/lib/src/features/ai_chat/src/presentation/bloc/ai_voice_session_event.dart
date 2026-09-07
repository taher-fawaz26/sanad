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
