import 'dart:async';

import 'package:sanad_client/src/features/ai_chat/src/domain/entities/ai_chat_attachment.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_speech_recognizer.dart';

/// Hand-rolled rather than mocktail: these fakes need to *drive* streams and
/// record call order, which a stub-and-verify mock expresses worse than a few
/// fields.
///
/// [FakeAudioPlayer] lives here for history rather than for the composer,
/// which owns no player: its one consumer is `mock_ai_voice_session_test.dart`,
/// where it stands in for the live-voice session's player.

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

  /// The two capabilities the AI cards added. Default to granted like the
  /// rest, so a test only sets the one it is about.
  AiPermissionOutcome location = AiPermissionOutcome.granted;
  AiPermissionOutcome notifications = AiPermissionOutcome.granted;

  /// Every capability this fake was asked for, in order — what an AI card's
  /// Allow control is asserted against.
  final List<String> requested = [];

  int settingsOpened = 0;

  /// Held to keep the microphone decision pending, so a test can act while
  /// dictation is still being brought up — the window the first-ever
  /// permission dialog occupies on a real device.
  Completer<void>? microphoneGate;

  @override
  Future<AiPermissionOutcome> ensureCamera() async {
    requested.add('camera');
    return camera;
  }

  @override
  Future<AiPermissionOutcome> ensureGallery() async {
    requested.add('gallery');
    return gallery;
  }

  @override
  Future<AiPermissionOutcome> ensureMicrophone() async {
    requested.add('microphone');
    if (microphoneGate != null) await microphoneGate!.future;
    return microphone;
  }

  @override
  Future<AiPermissionOutcome> ensureSpeechRecognition() async {
    requested.add('speechRecognition');
    return speechRecognition;
  }

  @override
  Future<AiPermissionOutcome> ensureLocation() async {
    requested.add('location');
    return location;
  }

  @override
  Future<AiPermissionOutcome> ensureNotifications() async {
    requested.add('notifications');
    return notifications;
  }

  @override
  Future<void> openSettings() async => settingsOpened++;
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
