import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localization/localization.dart';
import 'package:media_upload/media_upload.dart';
import 'package:network/network.dart';
import 'package:sanad_client/src/config/app_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/asset_picker_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/media_upload_ai_attachment_uploader.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/permissions_ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/just_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/record_audio_recorder.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/speech/speech_to_text_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_chat_page.dart';

/// Which wire a visit to the chat talks to the agent over.
///
/// Everything above the transport — the bloc, the protocol, the validator, the
/// renderer — is identical either way. This chooses a wire, nothing more.
enum AiChatTransport {
  /// A streamed `POST` per turn against the agent's SSE endpoint.
  ///
  /// The current real transport, while the agent team finalises the socket
  /// contract.
  sse,

  /// One WebSocket per visit. Retained as the reference transport.
  webSocket,

  /// The scripted local source, which is also the only transport that
  /// understands attachments today.
  mock
  ;

  /// Reads the route's query parameters.
  ///
  /// `?mock=1` wins over `?transport=`, and anything unrecognised — including
  /// absent — is [sse], so a typo degrades to the default rather than to no
  /// chat at all.
  static AiChatTransport fromQuery({String? mock, String? transport}) {
    if (mock == '1') return AiChatTransport.mock;
    return transport == 'ws' ? AiChatTransport.webSocket : AiChatTransport.sse;
  }
}

/// Owns everything scoped to one visit to the chat.
///
/// Stateful rather than building inside a `GoRoute.builder`, which can run more
/// than once and would leak a source, a recorder and a player per rebuild.
///
/// This is the composition root for the feature: it is the only place that
/// knows which concrete adapters exist. Everything below it — both blocs, every
/// widget — sees interfaces. The blocs own disposal, so the microphone and the
/// player are released when the screen goes away.
class AiChatScreen extends StatefulWidget {
  /// Creates the chat screen.
  const AiChatScreen({super.key, this.transport = AiChatTransport.sse});

  /// Which transport this visit uses.
  final AiChatTransport transport;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  /// Non-null only in mock mode; the page uses it to drive the dev picker.
  late final MockAiChatEventSource? _mock =
      widget.transport == AiChatTransport.mock ? MockAiChatEventSource() : null;

  /// Stable for this visit, so the server keeps conversation memory across
  /// turns — including across the separate HTTP request each SSE turn makes.
  final String _conversationId =
      'conv_${DateTime.now().microsecondsSinceEpoch}';

  /// Shared by the recorder and the player so audio focus is handed back and
  /// forth rather than fought over.
  late final AudioSessionManager _audioSession = AudioSessionManager();

  late final AiPermissionGateway _permissions =
      const PermissionsAiPermissionGateway();

  /// The composer, held so the lifecycle boundary below can reach it. Built
  /// here rather than in `BlocProvider.create` for that reason alone; the
  /// provider still owns closing it.
  late final AiComposerBloc _composer = AiComposerBloc(
    attachmentSource: AssetPickerAttachmentSource(permissions: _permissions),
    recorder: RecordAudioRecorder(session: _audioSession),
    player: JustAudioPlayer(session: _audioSession),
    permissions: _permissions,
    recognizer: SpeechToTextRecognizer(),
    // The same indirection `app_di.dart` already uses for the network layer's
    // `x-lang` header, and for the same reason: reading the service locator
    // from inside the bloc would make it untestable.
    resolveLanguageCode: () => sl<TranslateBloc>().state.languageCode,
  );

  /// The AI chat feature's one app-lifecycle boundary.
  ///
  /// Distinct from audio-session interruptions, which are a different signal
  /// with a different meaning and their own handlers: an interruption is
  /// another app taking the audio path, this is the OS putting us behind
  /// something else. Nothing downstream reports the latter — and on Android a
  /// backgrounded app without a foreground service stops receiving microphone
  /// data at all, so a capture that survives here is already dead.
  ///
  /// One listener, one event, and the bloc decides what that means for each
  /// capability it owns. The widget starts no work and holds no state.
  AppLifecycleListener? _lifecycle;

  late final AiChatEventSource _source = _mock ?? _buildLiveSource();

  /// Turns staged attachments into the `{id, url}` pairs a turn carries.
  ///
  /// Built here rather than resolved from `sl` inside the transport, for the
  /// same reason everything else on this screen is: a source that reaches into
  /// the service locator cannot be constructed in a test without one. The
  /// repository underneath *is* an app-wide singleton — it is stateless and
  /// outlives one visit — so this wrapper is the only per-visit part.
  AiAttachmentUploader _buildUploader() => MediaUploadAiAttachmentUploader(
    repository: sl<MediaUploadRepository>(),
  );

  AiChatEventSource _buildLiveSource() => switch (widget.transport) {
    AiChatTransport.sse => SseAiChatEventSource(
      url: Uri.parse(AppConfig.aiAgentStreamUrl),
      // The app's one token owner. Reading `TokenStorage` here instead would
      // be a second, unrefreshed view of the session.
      tokenManager: sl<TokenManager>(),
      conversationId: _conversationId,
      diagnostics: const LoggingAiUiDiagnosticsSink(),
      uploader: _buildUploader(),
    ),
    AiChatTransport.webSocket => WebSocketAiChatEventSource(
      url: Uri.parse(AppConfig.aiAgentSocketUrl),
      tokenManager: sl<TokenManager>(),
      conversationId: _conversationId,
      diagnostics: const LoggingAiUiDiagnosticsSink(),
      uploader: _buildUploader(),
    ),
    // Unreachable: `_mock` short-circuits this. Kept exhaustive so adding a
    // transport is a compile error here rather than a silent fallthrough.
    AiChatTransport.mock => MockAiChatEventSource(),
  };

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => _composer.add(const AiComposerBackgrounded()),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    // `BlocProvider.value` does not close what it is handed, so the composer
    // is closed here — and closing it is what releases the recorder, the
    // player and the recogniser.
    _composer.close().ignore();
    // The session the recorder and player share is owned here because neither
    // bloc can know when the other has finished with it.
    _audioSession.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => AiChatBloc(
          source: _source,
          validator: AiChatConfig.validator(
            // Unsupported components survive as a labelled marker in a dev
            // build and are dropped in release.
            keepUnsupportedNodes: !kReleaseMode,
          ),
          diagnostics: const LoggingAiUiDiagnosticsSink(),
        )..add(const AiChatStarted()),
      ),
      BlocProvider.value(value: _composer),
    ],
    child: AiChatPage(mockSource: _mock),
  );
}
