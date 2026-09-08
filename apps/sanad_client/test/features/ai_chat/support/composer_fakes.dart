import 'dart:async';

import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';

/// Hand-rolled rather than mocktail: these four fakes need to *drive* streams
/// and record call order, which a stub-and-verify mock expresses worse than a
/// few fields.

class FakeAttachmentSource implements AiAttachmentSource {
  FakeAttachmentSource({this.result = const AiAttachmentPickCancelled()});

  /// What the next [pick] returns.
  AiAttachmentPickResult result;

  /// Every intent asked for, in order.
  final List<AiAttachmentIntent> calls = <AiAttachmentIntent>[];

  /// Held to keep a pick pending, so a test can observe `isPicking`.
  Completer<void>? gate;

  @override
  Future<AiAttachmentPickResult> pick(AiAttachmentIntent intent) async {
    calls.add(intent);
    if (gate != null) await gate!.future;
    return result;
  }
}

class FakePermissionGateway implements AiPermissionGateway {
  FakePermissionGateway({
    this.camera = AiPermissionOutcome.granted,
    this.gallery = AiPermissionOutcome.granted,
    this.microphone = AiPermissionOutcome.granted,
  });

  AiPermissionOutcome camera;
  AiPermissionOutcome gallery;
  AiPermissionOutcome microphone;
  AiPermissionOutcome speechRecognition = AiPermissionOutcome.granted;

  int settingsOpened = 0;

  /// Held to keep the microphone decision pending, so a test can act while a
  /// take is still being brought up — the window the first-ever permission
  /// dialog occupies on a real device.
  Completer<void>? microphoneGate;

  @override
  Future<AiPermissionOutcome> ensureCamera() async => camera;

  @override
  Future<AiPermissionOutcome> ensureGallery() async => gallery;

  @override
  Future<AiPermissionOutcome> ensureMicrophone() async {
    if (microphoneGate != null) await microphoneGate!.future;
    return microphone;
  }

  @override
  Future<AiPermissionOutcome> ensureSpeechRecognition() async =>
      speechRecognition;

  @override
  Future<void> openSettings() async => settingsOpened++;
}

class FakeAudioRecorder implements AiAudioRecorder {
  final StreamController<AiRecordingSample> sampleController =
      StreamController<AiRecordingSample>.broadcast();
  final StreamController<AiRecordingAbort> abortController =
      StreamController<AiRecordingAbort>.broadcast();

  /// What [stop] returns. `null` models a take that produced nothing.
  String? stopPath = '/tmp/rec_1.m4a';

  bool available = true;
  bool throwOnStart = false;
  bool throwOnStop = false;

  int startCount = 0;
  int stopCount = 0;
  int cancelCount = 0;
  int disposeCount = 0;
  Duration? lastMaxDuration;
  final List<String> discarded = <String>[];

  @override
  Stream<AiRecordingSample> get samples => sampleController.stream;

  @override
  Stream<AiRecordingAbort> get aborts => abortController.stream;

  @override
  Future<bool> get isAvailable async => available;

  @override
  Future<void> start({required Duration maxDuration}) async {
    startCount++;
    lastMaxDuration = maxDuration;
    if (throwOnStart) throw StateError('recorder unavailable');
  }

  @override
  Future<String?> stop() async {
    stopCount++;
    if (throwOnStop) throw StateError('encode failed');
    return stopPath;
  }

  @override
  Future<void> cancel() async => cancelCount++;

  @override
  Future<void> discard(String path) async => discarded.add(path);

  @override
  Future<void> dispose() async {
    disposeCount++;
    await sampleController.close();
    await abortController.close();
  }

  /// Pushes a live reading without waiting for delivery.
  ///
  /// For `testWidgets`, where awaiting a zero delay inside the FakeAsync body
  /// never resolves — the caller pumps instead.
  void pushSample(double level, Duration elapsed) => sampleController.add(
    AiRecordingSample(level: level, elapsed: elapsed),
  );

  /// Pushes a live reading and lets it be delivered.
  Future<void> emitSample(double level, Duration elapsed) async {
    sampleController.add(
      AiRecordingSample(level: level, elapsed: elapsed),
    );
    await Future<void>.delayed(Duration.zero);
  }

  /// Pushes an abort and lets it be delivered.
  Future<void> emitAbort(AiRecordingAbort reason) async {
    abortController.add(reason);
    await Future<void>.delayed(Duration.zero);
  }
}

class FakeAudioPlayer implements AiAudioPlayer {
  final StreamController<AiPlaybackProgress> progressController =
      StreamController<AiPlaybackProgress>.broadcast();

  String? _currentId;
  bool throwOnPlay = false;

  final List<String> played = <String>[];

  /// Paths in play order, so a test can open what was actually handed over.
  final List<String> playedPaths = <String>[];
  int pauseCount = 0;
  int resumeCount = 0;
  int stopCount = 0;
  int disposeCount = 0;

  @override
  Stream<AiPlaybackProgress> get progress => progressController.stream;

  @override
  String? get currentId => _currentId;

  @override
  Future<void> play({required String id, required String path}) async {
    if (throwOnPlay) throw StateError('cannot open $path');
    _currentId = id;
    played.add(id);
    playedPaths.add(path);
  }

  @override
  Future<void> pause() async => pauseCount++;

  @override
  Future<void> resume() async => resumeCount++;

  @override
  Future<void> stop() async {
    stopCount++;
    _currentId = null;
  }

  @override
  Future<void> dispose() async {
    disposeCount++;
    await progressController.close();
  }

  /// Pushes a progress reading and lets it be delivered.
  Future<void> emitProgress(AiPlaybackProgress value) async {
    progressController.add(value);
    await Future<void>.delayed(Duration.zero);
  }
}

/// A one-line helper for the common "the picker returned these" setup.
AiAttachmentsPicked picked(List<AiChatAttachment> attachments) =>
    AiAttachmentsPicked(attachments);

/// A recogniser a test drives by hand.
class FakeSpeechRecognizer implements AiSpeechRecognizer {
  final StreamController<AiSpeechTranscript> transcriptController =
      StreamController<AiSpeechTranscript>.broadcast();
  final StreamController<AiSpeechFailure> failureController =
      StreamController<AiSpeechFailure>.broadcast();
  final StreamController<bool> listeningController =
      StreamController<bool>.broadcast();

  /// Whether [initialize] reports a usable recogniser.
  bool available = true;
  bool throwOnStart = false;

  /// What the device claims it can recognise.
  List<String> locales = <String>['en-US', 'ar-AE'];

  int initializeCount = 0;
  int startCount = 0;
  int stopCount = 0;
  int cancelCount = 0;
  int disposeCount = 0;

  /// Every locale [start] was asked for, in order — `null` means "device
  /// default".
  final List<String?> startedLocales = <String?>[];

  @override
  Stream<AiSpeechTranscript> get transcripts => transcriptController.stream;

  @override
  Stream<AiSpeechFailure> get failures => failureController.stream;

  @override
  Stream<bool> get listening => listeningController.stream;

  @override
  Future<bool> initialize() async {
    initializeCount++;
    return available;
  }

  @override
  Future<List<String>> availableLocales() async => locales;

  @override
  Future<void> start({String? localeId}) async {
    startCount++;
    startedLocales.add(localeId);
    if (throwOnStart) throw StateError('recogniser busy');
  }

  @override
  Future<void> stop() async => stopCount++;

  @override
  Future<void> cancel() async => cancelCount++;

  @override
  Future<void> dispose() async {
    disposeCount++;
    if (!transcriptController.isClosed) await transcriptController.close();
    if (!failureController.isClosed) await failureController.close();
    if (!listeningController.isClosed) await listeningController.close();
  }

  /// Pushes a result and lets it land.
  Future<void> emitTranscript(String text, {bool isFinal = false}) async {
    transcriptController.add(
      AiSpeechTranscript(text: text, isFinal: isFinal),
    );
    await Future<void>.delayed(Duration.zero);
  }

  /// Pushes a failure and lets it land.
  Future<void> emitFailure(AiSpeechFailure failure) async {
    failureController.add(failure);
    await Future<void>.delayed(Duration.zero);
  }

  /// Pushes a platform-driven listening change and lets it land.
  Future<void> emitListening({required bool value}) async {
    listeningController.add(value);
    await Future<void>.delayed(Duration.zero);
  }
}
