import 'package:core/core.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/pages/ai_chat_screen.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';

/// Contributes the AI chat prototype route.
///
/// The route is registered **only in non-release builds**. This is a
/// prototype: it talks to a scripted local source, has no persistence and no
/// auth, and must not be reachable from a shipped app. Gating here rather than
/// inside the page means the path does not exist at all in release, so nothing
/// can deep-link into it.
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

  @override
  List<RouteBase> routes(FeatureRouteContext context) => [
    if (!kReleaseMode)
      GoRoute(
        path: AiChatRoutes.chat,
        builder: (context, state) => const AiChatScreen(),
      ),
  ];
}
