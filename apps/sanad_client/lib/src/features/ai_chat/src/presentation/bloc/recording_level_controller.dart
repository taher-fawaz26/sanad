import 'package:flutter/foundation.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/level_history.dart';

/// Carries the live microphone reading for the take currently being recorded.
///
/// The audio equivalent of `ActiveStreamController`, and it exists for exactly
/// the same reason. A recording ticks many times a second; routing that through
/// the composer bloc's state would emit a new state — and therefore a new
/// attachment list — on every tick, rebuilding the composer and every tile on
/// a hot path.
///
/// Instead the bloc pipes the recorder's stream in here and emits *nothing*.
/// Only the recording bar listens (via `ValueListenableBuilder`), so exactly
/// one widget rebuilds per tick.
///
/// Both the amplitude and the elapsed time live here, because they arrive on
/// the same tick — which is also why the feature contains no `Timer` at all.
/// Alongside them it keeps a short [history] of recent levels, because a meter
/// that only knows the current number cannot show movement: one value can draw
/// a taller or shorter blob, but only a series can show a voice rising and
/// falling.
class RecordingLevelController extends ValueNotifier<AiRecordingSample> {
  /// Starts silent and at zero.
  RecordingLevelController({int historyLength = LevelHistory.defaultLength})
    : _history = LevelHistory(length: historyLength),
      super(AiRecordingSample.zero);

  final LevelHistory _history;

  /// Recent levels, oldest first, padded with silence before the take fills
  /// the window. A fresh list per tick, so a painter can compare by identity.
  List<double> get history => _history.values;

  /// Records one reading. Updates [history] *before* notifying, so a listener
  /// always sees the two agree.
  void add(AiRecordingSample sample) {
    _history.add(sample.level);
    value = sample;
  }

  /// Returns to silence, for when a take ends or is discarded.
  void reset() {
    _history.clear();
    value = AiRecordingSample.zero;
  }
}
