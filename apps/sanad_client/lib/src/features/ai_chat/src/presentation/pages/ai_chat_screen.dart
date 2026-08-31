import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/ai_chat_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/data/mock_ai_chat_event_source.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_chat_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_chat_page.dart';

/// Owns the event source for one visit to the chat.
///
/// Stateful rather than building the source inside a `GoRoute.builder`, which
/// can run more than once and would leak a source (and its stream) per rebuild.
/// The bloc closes the source when it closes, so the lifetimes line up.
class AiChatScreen extends StatefulWidget {
  /// Creates the chat screen.
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  late final MockAiChatEventSource _source = MockAiChatEventSource();

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => AiChatBloc(
      source: _source,
      validator: AiChatConfig.validator(
        // Unsupported components survive as a labelled marker in a dev build
        // and are dropped in release.
        keepUnsupportedNodes: !kReleaseMode,
      ),
      diagnostics: const LoggingAiUiDiagnosticsSink(),
    )..add(const AiChatStarted()),
    child: AiChatPage(mockSource: _source),
  );
}
