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
import 'package:sanad_client/src/features/ai_chat/src/data/mock_connectivity_service.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/asset_picker_attachment_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/media_upload_ai_attachment_uploader.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/permissions_ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/speech/speech_to_text_recognizer.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/sse_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/websocket_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_attachment_uploader.dart';
import 'package:sanad_client/src/features/ai_chat/src/domain/services/ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_composer_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/chat_context_cubit.dart';
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

  /// The local source that walks one deterministic service journey end to end.
  ///
  /// Not a second product: it answers on the same interfaces the live sources
  /// do, emits the same wire envelopes, and produces the same protocol nodes.
  /// Only the backend is simulated.
  mock
  ;

  /// Which transport this build uses.
  ///
  /// Read from configuration, never from the route. A journey that needed a URL
  /// to reach it was a separate product with a separate entry point; this is
  /// the normal chat, behaving deterministically because the build said so.
  static AiChatTransport resolve() =>
      AppConfig.useMockBackend ? AiChatTransport.mock : AiChatTransport.sse;

  /// Whether this transport is a local stand-in for the agent.
  bool get isLocal => this == AiChatTransport.mock;
}

/// Owns everything scoped to one visit to the chat.
///
/// Stateful rather than building inside a `GoRoute.builder`, which can run more
/// than once and would leak an event source and a recogniser per rebuild.
///
/// This is the composition root for the feature: it is the only place that
/// knows which concrete adapters exist. Everything below it — both blocs, every
/// widget — sees interfaces. The blocs own disposal, so the recogniser is
/// released when the screen goes away.
class AiChatScreen extends StatefulWidget {
  /// Creates the chat screen.
  const AiChatScreen({super.key, this.transport});

  /// Which transport this visit uses, or null to let the build decide.
  ///
  /// Overridable for tests and for the reference WebSocket transport, which has
  /// no UI entry point. A route never passes it: which wire a visit uses is
  /// [AiChatTransport.resolve]'s answer, read from configuration.
  final AiChatTransport? transport;

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  /// Which run of the conversation this is.
  ///
  /// The reason the per-visit objects below are rebuildable rather than
  /// `late final`. Restart bumps this, the key beneath it changes, and
  /// Flutter disposes the old `AiChatBloc` — which closes the transport, and
  /// with it the scenario engine, its timers and the interaction ledger. One
  /// integer clears the transcript, the stage, the answered cards, the staged
  /// attachments and the contextual sheet, because every one of those lives in
  /// an object this rebuild replaces. A bloc event could only ever have cleared
  /// the ones the bloc happens to own.
  ///
  /// For every other transport it never changes, and this behaves exactly as it
  /// always did.
  int _epoch = 0;

  /// Resolved once per visit rather than per build, so a rebuild cannot land
  /// the screen on a different wire than the one its bloc is talking over.
  late final AiChatTransport _transport =
      widget.transport ?? AiChatTransport.resolve();

  /// Stable for this visit, so the server keeps conversation memory across
  /// turns — including across the separate HTTP request each SSE turn makes.
  ///
  /// Deliberately not reset by [_restart]: the mock transport keeps no
  /// server-side memory, and a live transport is never restarted.
  final String _conversationId =
      'conv_${DateTime.now().microsecondsSinceEpoch}';

  late final AiPermissionGateway _permissions =
      const PermissionsAiPermissionGateway();

  /// Non-null only in mock mode.
  ///
  /// The page needs it for two things a live transport neither has nor should:
  /// the restart affordance, and the contextual content channel the journey
  /// publishes on.
  MockAiChatEventSource? _mock;

  /// The fake radio. Both local transports get one, because it is the only way
  /// to reach the bloc's offline queueing path without a real one.
  MockConnectivityService? _mockConnectivity;

  late AiChatEventSource _source;

  /// The composer, held so the lifecycle boundary below can reach it. Built
  /// here rather than in `BlocProvider.create` for that reason alone; this
  /// state owns closing it.
  late AiComposerBloc _composer;

  /// The AI chat feature's one app-lifecycle boundary.
  ///
  /// Distinct from audio-session interruptions, which are a different signal
  /// with a different meaning and their own handler over in the live-voice
  /// session: an interruption is another app taking the audio path, this is the
  /// OS putting us behind something else. Nothing downstream reports the latter
  /// — and on Android a backgrounded app without a foreground service stops
  /// receiving microphone data at all, so a recogniser that survives here is
  /// already dead.
  ///
  /// One listener, one event, and the bloc decides what that means for each
  /// capability it owns. The widget starts no work and holds no state.
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _buildRun();
    _lifecycle = AppLifecycleListener(
      onPause: () => _composer.add(const AiComposerBackgrounded()),
    );
  }

  /// Builds the objects scoped to one run of the conversation.
  void _buildRun() {
    _mock = _transport == AiChatTransport.mock ? MockAiChatEventSource() : null;
    _mockConnectivity = _transport.isLocal ? MockConnectivityService() : null;
    _source = _mock ?? _buildLiveSource();
    _composer = AiComposerBloc(
      attachmentSource: AssetPickerAttachmentSource(permissions: _permissions),
      permissions: _permissions,
      recognizer: SpeechToTextRecognizer(),
      // The same indirection `app_di.dart` already uses for the network layer's
      // `x-lang` header, and for the same reason: reading the service locator
      // from inside the bloc would make it untestable.
      resolveLanguageCode: () => sl<TranslateBloc>().state.languageCode,
    );
  }

  /// Tears the current run down and starts a fresh one.
  ///
  /// The event source is deliberately **not** disposed here: the `BlocProvider`
  /// owns the bloc, the bloc owns the source, and disposing it from both ends
  /// would close an already-closed controller. Dropping the reference and
  /// rebuilding under a new key is what triggers the ordered teardown.
  void _restart() {
    _mockConnectivity?.dispose().ignore();
    _composer.close().ignore();
    setState(() {
      _epoch += 1;
      _buildRun();
    });
  }

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

  AiChatEventSource _buildLiveSource() => switch (_transport) {
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
    // Unreachable: the local source short-circuits this. Kept exhaustive so
    // adding a transport is a compile error here rather than a silent
    // fallthrough.
    AiChatTransport.mock => MockAiChatEventSource(),
  };

  @override
  void dispose() {
    _lifecycle?.dispose();
    _mockConnectivity?.dispose().ignore();
    // `BlocProvider.value` does not close what it is handed, so the composer
    // is closed here — and closing it is what releases the recogniser.
    _composer.close().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    // Keyed by the run, so Restart disposes this whole subtree rather than
    // mutating it.
    key: ValueKey(_epoch),
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
          // Whether a turn can leave the device at all. The live transports
          // read the app's own service; the prototypes read the one the dev
          // picker can flip.
          connectivity: _mockConnectivity ?? sl<ConnectivityService>(),
        )..add(const AiChatStarted()),
      ),
      BlocProvider.value(value: _composer),
      // Scoped to the visit, like the conversation itself: contextual content
      // is about *this* conversation, and carrying it across visits would
      // offer a user offers for a request they have already left.
      //
      // A separate cubit rather than more `AiChatState` on purpose — see
      // `ChatContextCubit`'s own doc: it keeps the sheet and the transcript on
      // different rebuild boundaries.
      BlocProvider(create: (_) => ChatContextCubit(source: _mock)),
    ],
    child: AiChatPage(
      mockConnectivity: _mockConnectivity,
      onRestart: _mock == null ? null : _restart,
    ),
  );
}
