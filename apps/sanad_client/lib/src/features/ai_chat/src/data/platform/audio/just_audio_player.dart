import 'dart:async';

import 'package:just_audio/just_audio.dart' as ja;
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';

/// Plays one audio file at a time with `just_audio`.
///
/// The only file in the feature that names `just_audio`.
///
/// ## One player, on purpose
///
/// A single [ja.AudioPlayer] is created here and reused for every clip. The
/// alternative — a player per turn — is the failure mode a long live-voice
/// session hits: each one holds a platform decoder and a buffer, and twenty of
/// them will be killed by the OS. Loading a second clip stops and replaces the
/// first, which is also what a spoken conversation wants.
class JustAudioPlayer implements AiAudioPlayer {
  /// Creates the player.
  ///
  /// [session] is shared with the capture path so focus is handed back and
  /// forth rather than fought over.
  ///
  /// [sessionMode] is the category this player asks for. It defaults to
  /// [AudioSessionMode.playback], which is right when playback is the only
  /// thing happening. A **duplex** caller — the live-voice session, where the
  /// microphone stays open while the assistant talks so the user can barge in
  /// — must pass [AudioSessionMode.recording] instead: reconfiguring to a
  /// playback-only category mid-session would pull the capture path out from
  /// under its own open microphone.
  JustAudioPlayer({
    required AudioSessionManager session,
    AudioSessionMode sessionMode = AudioSessionMode.playback,
  }) : _session = session,
       _sessionMode = sessionMode {
    _stateSubscription = _player.playerStateStream.listen(_onPlayerState);
    _positionSubscription = _player.positionStream.listen(_onPosition);
  }

  final AudioSessionManager _session;
  final AudioSessionMode _sessionMode;
  final ja.AudioPlayer _player = ja.AudioPlayer();

  final StreamController<AiPlaybackProgress> _progress =
      StreamController<AiPlaybackProgress>.broadcast();

  StreamSubscription<ja.PlayerState>? _stateSubscription;
  StreamSubscription<Duration>? _positionSubscription;

  String? _currentId;
  bool _disposed = false;

  @override
  Stream<AiPlaybackProgress> get progress => _progress.stream;

  @override
  String? get currentId => _currentId;

  @override
  Future<void> play({required String id, required String path}) async {
    if (_disposed) return;

    await _session.activate(_sessionMode);
    // Replaces whatever was loaded; `setFilePath` stops the previous source.
    await _player.setFilePath(path);
    if (_disposed) return;

    _currentId = id;
    // Deliberately not awaited: `play()` completes when playback *finishes*,
    // and awaiting it here would hang the caller for the length of the clip.
    unawaited(_player.play());
  }

  @override
  Future<void> pause() async {
    if (_disposed) return;
    await _player.pause();
  }

  @override
  Future<void> resume() async {
    if (_disposed || _currentId == null) return;
    unawaited(_player.play());
  }

  @override
  Future<void> stop() async {
    if (_disposed) return;
    _currentId = null;
    await _player.stop();
    await _session.deactivate();
    _emit(AiPlaybackProgress.idle);
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    await _stateSubscription?.cancel();
    await _positionSubscription?.cancel();
    _stateSubscription = null;
    _positionSubscription = null;
    _currentId = null;

    await _player.dispose();
    await _session.deactivate();

    if (!_progress.isClosed) await _progress.close();
  }

  void _onPlayerState(ja.PlayerState state) {
    if (state.processingState == ja.ProcessingState.completed) {
      // Rewind rather than leave the head at the end, so tapping play again
      // restarts the clip instead of doing nothing.
      unawaited(_player.seek(Duration.zero));
      unawaited(_player.pause());
      _emit(_snapshot(position: Duration.zero, isPlaying: false));
      return;
    }
    _emit(_snapshot(isPlaying: state.playing));
  }

  void _onPosition(Duration position) =>
      _emit(_snapshot(position: position, isPlaying: _player.playing));

  AiPlaybackProgress _snapshot({required bool isPlaying, Duration? position}) =>
      AiPlaybackProgress(
        position: position ?? _player.position,
        duration: _player.duration ?? Duration.zero,
        isPlaying: isPlaying,
      );

  void _emit(AiPlaybackProgress value) {
    if (_disposed || _progress.isClosed) return;
    _progress.add(value);
  }
}
