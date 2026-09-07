import 'package:flutter/foundation.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';

/// What is playing, and how far in.
@immutable
class AudioPlaybackValue {
  /// Creates a playback value.
  const AudioPlaybackValue({
    this.attachmentId,
    this.progress = AiPlaybackProgress.idle,
  });

  /// The attachment currently loaded, or `null` when nothing is.
  final String? attachmentId;

  /// Position and duration for [attachmentId].
  final AiPlaybackProgress progress;

  /// Nothing loaded.
  static const AudioPlaybackValue idle = AudioPlaybackValue();

  /// Whether [id] is the clip currently playing.
  bool isPlaying(String id) => attachmentId == id && progress.isPlaying;

  /// Whether [id] is loaded at all, playing or paused.
  bool isLoaded(String id) => attachmentId == id;

  @override
  bool operator ==(Object other) =>
      other is AudioPlaybackValue &&
      other.attachmentId == attachmentId &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(attachmentId, progress);
}

/// Carries playback position for the one clip that is playing.
///
/// The same hot-path bargain as `RecordingLevelController`: position updates
/// arrive many times a second and must not become bloc state, so they land
/// here and only the audio row listens.
///
/// **One clip at a time, by construction.** [AudioPlaybackValue.attachmentId]
/// names it, so a row can ask "is this about me?" and ignore ticks that are
/// not. That is what stops the feature retaining a player per message — the
/// failure mode a conversation full of voice notes would otherwise hit.
class AudioPlaybackController extends ValueNotifier<AudioPlaybackValue> {
  /// Starts idle.
  AudioPlaybackController() : super(AudioPlaybackValue.idle);

  /// Points the controller at [attachmentId] and resets its progress.
  void load(String attachmentId) =>
      value = AudioPlaybackValue(attachmentId: attachmentId);

  /// Records a progress reading for whatever is loaded.
  void update(AiPlaybackProgress progress) => value = AudioPlaybackValue(
    attachmentId: value.attachmentId,
    progress: progress,
  );

  /// Unloads, for when playback stops or the clip is deleted.
  void clear() => value = AudioPlaybackValue.idle;
}
