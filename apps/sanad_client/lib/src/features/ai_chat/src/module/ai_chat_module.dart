import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_chat_screen.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_home_shell.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_ui_showcase_page.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_voice_session_screen.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/features/history/history_page.dart';
import 'package:sanad_client/src/features/history/src/data/mock_conversation_history_source.dart';
import 'package:sanad_client/src/features/my_life/my_life_page.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_requests_page.dart';

/// Contributes the AI chat prototype route.
///
/// The route is registered **only in non-release builds**. This is a
/// prototype: it has no persistence and no conversation history, and must not
/// be reachable from a shipped app. Gating here rather than inside the page
/// means the path does not exist at all in release, so nothing can deep-link
/// into it.
class AiChatModule extends FeatureModule {
  @override
  String get name => 'ai_chat';

  @override
  String get version => '0.1.0';

  @override
  List<String> get dependencies => const [];

  @override
  void registerDependencies() {
    // Nothing global to register: the event source and bloc are scoped to one
    // visit (see AiChatScreen), and the validator is built from
    // AiChatConfig's compile-time policy rather than injected.
  }

  static ClientRequestsListBloc _buildRequestsListBloc() =>
      sl<ClientRequestsListBloc>();

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    if (!kReleaseMode)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AiHomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AiChatRoutes.chat,
                // Two dev affordances on one route, so neither needs a second
                // screen: `?mock=1` replays the scripted scenarios —
                // including the deliberately-broken payloads the real agent
                // never sends — and `?transport=ws` reaches the reference
                // WebSocket transport. A plain visit uses the streamed POST.
                builder: (context, state) => AiChatScreen(
                  transport: AiChatTransport.fromQuery(
                    mock: state.uri.queryParameters['mock'],
                    transport: state.uri.queryParameters['transport'],
                  ),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AiChatRoutes.requests,
                // The real feature, not the old placeholder. The shell branch
                // and the top-level `/requests` route render the same page;
                // only this one carries the shell's header chrome.
                builder: (context, state) =>
                    ClientRequestsPage(buildBloc: _buildRequestsListBloc),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AiChatRoutes.myLife,
                builder: (context, state) => const MyLifePage(),
              ),
            ],
          ),
        ],
      ),
    // Not a shell branch: reached by push from any branch, and pushing
    // covers the whole shell — including its header — which is what a
    // full-screen live-voice session and a "look back" history excursion
    // both want.
    if (!kReleaseMode)
      GoRoute(
        path: AiChatRoutes.voice,
        builder: (context, state) => const AiVoiceSessionScreen(),
      ),
    if (!kReleaseMode)
      GoRoute(
        path: AiChatRoutes.history,
        // `?state=empty` serves the empty fixture, following the `?mock=` /
        // `?transport=` affordances on the chat route above. Both of
        // History's Figma states are reachable in a debug build without a
        // rebuild, a switch in the UI, or any mock behaviour that could
        // survive into release — the route itself does not exist there.
        builder: (context, state) => HistoryPage(
          source: MockConversationHistorySource(
            fixture: ConversationHistoryFixture.fromQuery(
              state.uri.queryParameters['state'],
            ),
          ),
        ),
      ),
    if (!kReleaseMode)
      GoRoute(
        path: AiChatRoutes.showcase,
        builder: (context, state) => const AiUiShowcasePage(),
      ),
  ];
}
