import 'package:core/core.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/config/app_config.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_chat_screen.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_home_shell.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_voice_session_screen.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/bloc/client_requests_list/client_requests_list_bloc.dart';
import 'package:sanad_client/src/features/client_requests/src/presentation/pages/client_requests_page.dart';
import 'package:sanad_client/src/features/history/history_page.dart';
import 'package:sanad_client/src/features/history/src/data/mock_conversation_history_source.dart';
import 'package:sanad_client/src/features/my_life/my_life_page.dart';

/// Contributes the AI chat shell and its sibling routes.
///
/// Registration is gated on [AppConfig.enableAiChatShell], a compile-time
/// constant, so the whole shell is present in every non-production build and
/// tree-shaken out of a production binary. This is independent of the backend:
/// a real-backend build (`MOCK_BACKEND=false`) and a deterministic-journey
/// build (`MOCK_BACKEND=true`) both expose the same shell as the app's home —
/// only the transport behind the chat and the requests repository differ. This
/// is not `/dev`-gated and carries no demo affordance: from the user's
/// perspective it is the normal app.
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
    if (AppConfig.enableAiChatShell)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AiHomeShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AiChatRoutes.chat,
                // No query parameters. Which transport this build talks to is
                // decided by `AppConfig.useMockBackend`, so there is one chat
                // route, one screen, and nothing to remember to append.
                builder: (context, state) => const AiChatScreen(),
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
                // The shell's nav pill already says "Requests", so the page
                // does not repeat it here (C-08).
                //
                // One builder, always the registered bloc. Whether the
                // repository behind it reaches the API or a fixture set is
                // decided once in `ClientRequestsDI`, so this renders the
                // normal screen in both cases.
                builder: (context, state) => const ClientRequestsPage(
                  buildBloc: _buildRequestsListBloc,
                  showNavBar: false,
                ),
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
    if (AppConfig.enableAiChatShell)
      GoRoute(
        path: AiChatRoutes.voice,
        builder: (context, state) => const AiVoiceSessionScreen(),
      ),
    if (AppConfig.enableAiChatShell)
      GoRoute(
        path: AiChatRoutes.history,
        // `?state=empty` serves the empty fixture, so both of History's Figma
        // states are reachable in a debug build without a rebuild, a switch in
        // the UI, or any mock behaviour that could survive into release — the
        // route itself does not exist there.
        builder: (context, state) => HistoryPage(
          source: MockConversationHistorySource(
            fixture: ConversationHistoryFixture.fromQuery(
              state.uri.queryParameters['state'],
            ),
          ),
        ),
      ),
  ];
}
