import 'dart:async';
import 'dart:typed_data';

import 'package:sanad_client/src/features/ai_chat/src/domain/enums/ai_voice_session_status.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_capture.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_voice_session.dart';

/// A microphone that yields whatever frames a test pushes into it.
class FakeVoiceCapture implements AiVoiceCapture {
  final StreamController<Uint8List> frames =
      StreamController<Uint8List>.broadcast();

  bool available = true;
  bool throwOnStart = false;
  int startCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<Stream<Uint8List>> start() async {
    startCount++;
    if (throwOnStart) throw StateError('microphone busy');
    return frames.stream;
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> dispose() async {
    disposeCount++;
    if (!frames.isClosed) await frames.close();
  }

  /// Pushes one frame of 16-bit PCM at [amplitude] (0..1) and lets it land.
  Future<void> emit(double amplitude, {int samples = 256}) async {
    final data = Int16List(samples);
    final value = (amplitude.clamp(0.0, 1.0) * 32767).round();
    for (var i = 0; i < samples; i++) {
      // Alternating so the RMS of the frame is the amplitude itself, which
      // makes a test's threshold arithmetic obvious rather than empirical.
      data[i] = i.isEven ? value : -value;
    }
    frames.add(data.buffer.asUint8List());
    await Future<void>.delayed(Duration.zero);
  }
}

/// A session that records what it was asked to do, for the bloc's tests.
class FakeVoiceSession implements AiVoiceSession {
  final StreamController<AiVoiceSessionStatus> statusController =
      StreamController<AiVoiceSessionStatus>.broadcast();
  final StreamController<double> levelController =
      StreamController<double>.broadcast();

  @override
  String? failureKey;

  int startCount = 0;
  int finishTurnCount = 0;
  int interruptCount = 0;
  int endCount = 0;
  int disposeCount = 0;
  final List<bool> muteCalls = <bool>[];

  @override
  Stream<AiVoiceSessionStatus> get status => statusController.stream;

  @override
  Stream<double> get inputLevel => levelController.stream;

  @override
  Future<void> start() async => startCount++;

  @override
  Future<void> setMuted({required bool muted}) async => muteCalls.add(muted);

  @override
  Future<void> finishTurn() async => finishTurnCount++;

  @override
  Future<void> interrupt() async => interruptCount++;

  @override
  Future<void> end() async => endCount++;

  @override
  Future<void> dispose() async {
    disposeCount++;
    if (!statusController.isClosed) await statusController.close();
    if (!levelController.isClosed) await levelController.close();
  }

  /// Pushes a transition and lets it land.
  Future<void> emitStatus(AiVoiceSessionStatus value) async {
    statusController.add(value);
    await Future<void>.delayed(Duration.zero);
  }

  /// Pushes a level reading and lets it land.
  Future<void> emitLevel(double value) async {
    levelController.add(value);
    await Future<void>.delayed(Duration.zero);
  }
}
