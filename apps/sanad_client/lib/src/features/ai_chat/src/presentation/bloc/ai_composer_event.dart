part of 'ai_composer_bloc.dart';

/// Everything the composer reacts to.
///
/// The widget layer emits *intents* — "the user asked for the camera" — and
/// never actions. It does not know that a picker exists, that a permission
/// might be needed, or what a recording is encoded as.
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

/// The user pressed record.
final class AiComposerRecordingStarted extends AiComposerEvent {
  /// Creates the start.
  const AiComposerRecordingStarted({this.autoLock = false});

  /// Whether the take should come up already hands-free.
  ///
  /// Exists for the accessibility path, where holding a control for the length
  /// of a message is not an interaction every user can perform, so a plain tap
  /// starts a locked take and the explicit stop/delete controls are the whole
  /// interaction.
  ///
  /// A flag on *this* event rather than a following
  /// [AiComposerRecordingLocked], because `sequential()` orders events only
  /// within one event type — `Bloc.on<E>` filters the stream by `E` before
  /// applying the transformer — so two events would race the permission
  /// round-trip instead of composing. One event, one handler, one decision
  /// point: no race is possible because there is no second event to order.
  final bool autoLock;

  @override
  List<Object?> get props => [autoLock];
}

/// The user swiped up past the lock threshold; keep recording after they let
/// go.
///
/// Nothing is asked of the recorder — the microphone is already live and stays
/// live. This changes only which interaction ends the take.
final class AiComposerRecordingLocked extends AiComposerEvent {
  /// Creates the lock.
  const AiComposerRecordingLocked();
}

/// The user tapped the microphone instead of holding it.
///
/// Emits a hint and nothing else. A tap must never start a take: the whole
/// point of the hold threshold is that a brush against the button cannot put a
/// voice message into the conversation.
final class AiComposerRecordingHintRequested extends AiComposerEvent {
  /// Creates the hint request.
  const AiComposerRecordingHintRequested();
}

/// The user pressed stop; keep the take for preview.
final class AiComposerRecordingStopped extends AiComposerEvent {
  /// Creates the stop.
  const AiComposerRecordingStopped();
}

/// The user cancelled mid-take; throw it away.
final class AiComposerRecordingCancelled extends AiComposerEvent {
  /// Creates the cancellation.
  const AiComposerRecordingCancelled();
}

/// The platform took the microphone away mid-take.
///
/// Raised from the recorder's own stream rather than by the UI, so an
/// interruption is handled identically whether or not anyone is looking.
final class AiComposerRecordingAborted extends AiComposerEvent {
  /// Creates the abort.
  const AiComposerRecordingAborted(this.reason);

  /// Why the take ended.
  final AiRecordingAbort reason;

  @override
  List<Object?> get props => [reason];
}

/// The user tapped play or pause on a voice note.
final class AiComposerPlaybackToggled extends AiComposerEvent {
  /// Creates the toggle.
  const AiComposerPlaybackToggled(this.attachment);

  /// The voice note to play or pause.
  ///
  /// The whole attachment rather than its id, because one player serves both
  /// halves of the screen. A staged take can be looked up in
  /// [AiComposerState.attachments]; a take that has already been **sent**
  /// cannot — submitting clears the composer, and the attachment now belongs
  /// to a message in the conversation. Looking the id up here is what used to
  /// make the play button on a sent voice note do nothing at all.
  final AiAudioAttachment attachment;

  @override
  List<Object?> get props => [attachment];
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

/// Stop any playing voice note and release the audio session.
///
/// Used when something else is about to want the speaker — opening live voice,
/// for one — so the decision stays with the bloc that owns the player rather
/// than being a `stop()` call from a widget.
final class AiComposerPlaybackStopped extends AiComposerEvent {
  /// Creates the stop.
  const AiComposerPlaybackStopped();
}

/// The app went to the background, or the screen was torn down.
///
/// Deliberately **not** an audio-session interruption. An interruption is
/// another app taking the audio path and is handled by the recorder and the
/// voice session; this is the OS telling us we are no longer in front of the
/// user, which nothing downstream reports. They are separate signals with
/// separate handlers precisely so neither has to guess which one it is.
final class AiComposerBackgrounded extends AiComposerEvent {
  /// Creates the notification.
  const AiComposerBackgrounded();
}
