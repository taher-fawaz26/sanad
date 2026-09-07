import 'package:equatable/equatable.dart';

/// Where playback has reached.
final class AiPlaybackProgress extends Equatable {
  /// Creates a progress reading.
  const AiPlaybackProgress({
    required this.position,
    required this.duration,
    required this.isPlaying,
  });

  /// How far in.
  final Duration position;

  /// Total length, or [Duration.zero] before it is known.
  final Duration duration;

  /// Whether audio is currently coming out.
  final bool isPlaying;

  /// Nothing loaded.
  static const AiPlaybackProgress idle = AiPlaybackProgress(
    position: Duration.zero,
    duration: Duration.zero,
    isPlaying: false,
  );

  /// Completion in 0..1, or 0 when the duration is unknown.
  double get fraction => duration.inMilliseconds <= 0
      ? 0
      : (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [position, duration, isPlaying];
}

/// Plays one audio file at a time.
///
/// **One instance serves the whole screen.** Playing a second clip stops the
/// first, which is what stops the feature from retaining a player per message
/// — the failure mode a chat full of voice notes would otherwise hit.
///
/// The implementation is the only thing in the feature that knows `just_audio`
/// exists.
abstract interface class AiAudioPlayer {
  /// Position updates for whatever is loaded. Broadcast; silent when idle.
  Stream<AiPlaybackProgress> get progress;

  /// The id passed to the most recent [play], or `null` when nothing is
  /// loaded. Lets a row decide whether the progress stream is about *it*.
  String? get currentId;

  /// Loads and plays [path], tagging the session with [id].
  ///
  /// Stops and releases whatever was playing first.
  Future<void> play({required String id, required String path});

  /// Pauses without unloading, so [resume] can continue.
  Future<void> pause();

  /// Resumes a paused clip.
  Future<void> resume();

  /// Stops and unloads.
  Future<void> stop();

  /// Releases the player. Safe while playing, and safe to call twice.
  Future<void> dispose();
}
