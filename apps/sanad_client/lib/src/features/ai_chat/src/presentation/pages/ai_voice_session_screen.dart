import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/attachments/permissions_ai_permission_gateway.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/audio_session_manager.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/audio/just_audio_player.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/mock_ai_voice_session.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/mock_voice_scenarios.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/platform/voice/record_voice_capture.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_action_handlers.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_voice_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_voice_session_page.dart';

/// Owns the live-voice subsystem for one visit.
///
/// The composition root for voice, mirroring `AiChatScreen`: the only place
/// that names a concrete adapter. Stateful for the same reason — a
/// `GoRoute.builder` can run more than once, and a microphone opened per
/// rebuild would never be released.
///
/// Real microphone, mocked assistant. `RecordVoiceCapture` yields genuine PCM
/// from the device; only what the assistant *says* is simulated, by playing
/// back what was just captured. The bloc disposes the session, and the session
/// releases the capture, the player and the audio focus — so backing out of
/// this route hands the microphone back whatever state it was in.
class AiVoiceSessionScreen extends StatefulWidget {
  /// Creates the screen.
  const AiVoiceSessionScreen({super.key});

  @override
  State<AiVoiceSessionScreen> createState() => _AiVoiceSessionScreenState();
}

class _AiVoiceSessionScreenState extends State<AiVoiceSessionScreen> {
  /// Shared by the capture and the player so audio focus is handed back and
  /// forth rather than fought over. Owned here because neither can know when
  /// the other has finished with it.
  late final AudioSessionManager _audioSession = AudioSessionManager();

  late final AiVoiceSessionBloc _bloc = AiVoiceSessionBloc(
    session: MockAiVoiceSession(
      capture: RecordVoiceCapture(),
      // Duplex: the microphone stays open while the assistant speaks, so the
      // player must keep the capture-capable category rather than switch the
      // session to playback-only underneath it.
      player: JustAudioPlayer(
        session: _audioSession,
        sessionMode: AudioSessionMode.recording,
      ),
      session: _audioSession,
      // The scripted semantic beats. Opt-in: without it the session is the
      // echo-only mock it has always been, which is what the existing mock
      // tests exercise.
      uiScript: MockVoiceScenarios.standard,
    ),
    permissions: const PermissionsAiPermissionGateway(),
    validator: AiChatConfig.validator(keepUnsupportedNodes: !kReleaseMode),
    diagnostics: const LoggingAiUiDiagnosticsSink(),
  );

  /// Built once, for the same reason the chat page builds its own once:
  /// `AiUiHost` compares environments to decide whether to notify, and a fresh
  /// instance per build would invalidate the panel on every frame.
  late final AiUiEnvironment _environment = AiUiEnvironment(
    registry: defaultRendererRegistry(
      showUnsupportedMarker: !kReleaseMode,
    ),
    // A *narrowed* registry. `send_message` is absent on purpose: there is no
    // conversation to post a turn into during a voice session, and the answer
    // leaves over the session's own channel instead. Capability requests stay,
    // because a permission prompt is as meaningful here as it is in chat.
    actions: buildAiChatActionRegistry(
      onSendMessage: (_) {},
      interactions: AiVoiceInteractionSink(_bloc),
    ),
    diagnostics: const LoggingAiUiDiagnosticsSink(),
    interactions: AiVoiceInteractionSink(_bloc),
    ledger: _bloc.ledger,
    strings: AiUiStrings(
      metresSuffix: 'ai_chat.unit_metres'.tr(),
      kilometresSuffix: 'ai_chat.unit_kilometres'.tr(),
      unsupportedContent: 'ai_chat.unsupported_content'.tr(),
      openInMaps: 'ai_chat.open_in_maps'.tr(),
      ratingOutOfFive: 'ai_chat.rating_out_of_five'.tr(),
      distanceLabel: 'ai_chat.distance_label'.tr(),
    ),
  );

  /// This route's app-lifecycle boundary — the same concept as the chat
  /// screen's, scoped to the session this route owns. Separate from audio
  /// interruptions, which the session already handles on its own signal.
  AppLifecycleListener? _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onPause: () => _bloc.add(const AiVoiceSessionBackgrounded()),
    );
  }

  @override
  void dispose() {
    _lifecycle?.dispose();
    // `BlocProvider.value` does not close what it is handed, and closing the
    // bloc is what releases the capture, the player and the mock session.
    _bloc.close().ignore();
    _audioSession.dispose().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _bloc,
    child: AiUiHost(
      environment: _environment,
      child: const AiVoiceSessionPage(),
    ),
  );
}
