import 'package:equatable/equatable.dart';

/// One reading from the live microphone.
///
/// Amplitude and elapsed time travel together on purpose: they come from the
/// same underlying tick, so pairing them means the recording bar needs exactly
/// one subscription and there is no `Timer` anywhere in the feature.
final class AiRecordingSample extends Equatable {
  /// Creates a sample.
  const AiRecordingSample({required this.level, required this.elapsed});

  /// Normalised 0..1 loudness. Already converted from the platform's dBFS, so
  /// no consumer needs to know what a decibel is.
  final double level;

  /// How long the current take has been running.
  final Duration elapsed;

  /// A silent reading at zero elapsed — the value the bar shows before the
  /// first tick arrives.
  static const AiRecordingSample zero = AiRecordingSample(
    level: 0,
    elapsed: Duration.zero,
  );

  @override
  List<Object?> get props => [level, elapsed];
}

/// Why a take ended without producing a file.
enum AiRecordingAbort {
  /// The user cancelled.
  cancelled,

  /// The audio session was taken away — a call, or the headset was unplugged.
  interrupted,

  /// The platform failed.
  failed,
}

/// Captures a single voice note to a file.
///
/// The implementation is the only thing in the feature that knows `record`
/// exists. It owns its subscriptions and temp file and must release both on
/// [dispose], including mid-recording.
abstract interface class AiAudioRecorder {
  /// Live readings while a take is running. Broadcast, and silent otherwise.
  ///
  /// A `Stream` rather than a `ValueListenable` because this is the domain
  /// layer and `dep_rules.yaml` forbids it importing Flutter. The presentation
  /// layer adapts it to a listenable so exactly one widget rebuilds per tick.
  Stream<AiRecordingSample> get samples;

  /// Raised when the platform pulls the audio session out from under a take.
  Stream<AiRecordingAbort> get aborts;

  /// Whether the device has a usable microphone.
  Future<bool> get isAvailable;

  /// Begins capturing. Assumes permission is already granted.
  ///
  /// [maxDuration] stops the take automatically, which is what keeps a
  /// recording inside `FileSizePolicy`'s ceiling without the UI policing it.
  Future<void> start({required Duration maxDuration});

  /// Ends the take and returns the finished file path, or `null` if nothing
  /// usable was captured.
  Future<String?> stop();

  /// Ends the take and discards the file.
  Future<void> cancel();

  /// Deletes a file this recorder produced.
  ///
  /// File I/O lives behind the interface so no bloc imports `dart:io`. Only
  /// recorder-produced files are ever passed here — picker files belong to the
  /// picker's cache and are not ours to delete.
  Future<void> discard(String path);

  /// Releases the recorder, any subscription, and any partial file.
  /// Safe to call while recording, and safe to call twice.
  Future<void> dispose();
}
