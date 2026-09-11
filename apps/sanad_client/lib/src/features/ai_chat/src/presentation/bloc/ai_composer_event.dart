part of 'ai_composer_bloc.dart';

/// Everything the composer reacts to.
///
/// The widget layer emits *intents* — "the user asked for the camera" — and
/// never actions. It does not know that a picker exists, that a permission
/// might be needed, or how speech reaches the device's recogniser.
sealed class AiComposerEvent extends Equatable {
  /// Const so subclasses can be const.
  const AiComposerEvent();

  @override
  List<Object?> get props => [];
}

/// The user asked to attach something from [intent].
final class AiComposerAttachmentRequested extends AiComposerEvent {
  /// Creates the request.
  const AiComposerAttachmentRequested(this.intent);

  /// Which acquisition flow to run.
  final AiAttachmentIntent intent;

  @override
  List<Object?> get props => [intent];
}

/// The user removed the attachment with [id].
final class AiComposerAttachmentRemoved extends AiComposerEvent {
  /// Creates the removal.
  const AiComposerAttachmentRemoved(this.id);

  /// Which attachment to drop.
  final String id;

  @override
  List<Object?> get props => [id];
}

/// The turn was sent; drop everything without deleting the files, which now
/// belong to a message.
final class AiComposerSubmitted extends AiComposerEvent {
  /// Creates the submission acknowledgement.
  const AiComposerSubmitted();
}

/// The notice has been shown; stop reporting it.
final class AiComposerNoticeDismissed extends AiComposerEvent {
  /// Creates the dismissal.
  const AiComposerNoticeDismissed();
}

/// The user accepted the offer to open system settings.
final class AiComposerSettingsRequested extends AiComposerEvent {
  /// Creates the request.
  const AiComposerSettingsRequested();
}

/// The user asked to dictate.
final class AiComposerSpeechStarted extends AiComposerEvent {
  /// Creates the request.
  const AiComposerSpeechStarted();
}

/// The user asked to finish dictating and keep the text.
final class AiComposerSpeechStopped extends AiComposerEvent {
  /// Creates the stop.
  const AiComposerSpeechStopped();
}

/// The user threw the dictation away.
final class AiComposerSpeechCancelled extends AiComposerEvent {
  /// Creates the cancellation.
  const AiComposerSpeechCancelled();
}

/// The recogniser stopped by itself.
///
/// Not the same as [AiComposerSpeechStopped]: nobody pressed anything. A
/// recogniser built for short phrases ends the session after a pause, and the
/// composer has to follow rather than keep claiming to listen.
final class AiComposerSpeechEnded extends AiComposerEvent {
  /// Creates the notification.
  const AiComposerSpeechEnded();
}

/// Recognition could not continue.
final class AiComposerSpeechFailed extends AiComposerEvent {
  /// Creates the failure.
  const AiComposerSpeechFailed(this.failure);

  /// Why it stopped.
  final AiSpeechFailure failure;

  @override
  List<Object?> get props => [failure];
}

/// The app went to the background, or the screen was torn down.
///
/// Deliberately **not** an audio-session interruption. An interruption is
/// another app taking the audio path and is handled by the live-voice
/// session; this is the OS telling us we are no longer in front of the user,
/// which nothing downstream reports. They are separate signals with
/// separate handlers precisely so neither has to guess which one it is.
final class AiComposerBackgrounded extends AiComposerEvent {
  /// Creates the notification.
  const AiComposerBackgrounded();
}
