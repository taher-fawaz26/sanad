import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/module/ai_chat_module.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';

/// The route shape `AiChatModule` builds — specifically, that Sanad/Requests/
/// My Life are genuinely shell branches (so go_router preserves each one's
/// state across a switch) while live voice and History are plain routes
/// reached by push (so either covers the whole shell, including its header,
/// rather than replacing one branch).
///
/// This is a structural check on the route tree, not a live navigation test:
/// branch-state preservation itself is `StatefulShellRoute.indexedStack`'s own
/// contract, not this feature's code — what belongs to this feature, and what
/// a regression here would actually catch, is *which* routes are branches.
void main() {
  const context = FeatureRouteContext(homeRoute: '/home');

  test('the module contributes shell branches plus two push routes', () {
    final routes = AiChatModule().routes(context);

    final shells = routes.whereType<StatefulShellRoute>().toList();
    final pushRoutes = routes.whereType<GoRoute>().toList();

    expect(shells, hasLength(1), reason: 'exactly one Home shell');
    expect(
      pushRoutes.map((r) => r.path),
      containsAll([AiChatRoutes.voice, AiChatRoutes.history]),
      reason: 'live voice and History must be reachable by push, not branch',
    );
  });

  test('the shell has exactly the three peer branches, at their routes', () {
    final shell = AiChatModule()
        .routes(context)
        .whereType<StatefulShellRoute>()
        .single;

    final branchPaths = shell.branches
        .expand((branch) => branch.routes)
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toList();

    expect(shell.branches, hasLength(3));
    expect(
      branchPaths,
      containsAll([
        AiChatRoutes.chat,
        AiChatRoutes.requests,
        AiChatRoutes.myLife,
      ]),
    );
  });

  test('live voice and History are not nested inside the shell', () {
    final routes = AiChatModule().routes(context);
    final shell = routes.whereType<StatefulShellRoute>().single;

    final branchPaths = shell.branches
        .expand((branch) => branch.routes)
        .whereType<GoRoute>()
        .map((route) => route.path)
        .toSet();

    // A route nested inside a branch would replace that branch's content
    // instead of covering the shell's header — the opposite of what a
    // full-screen live-voice session or a "look back" excursion needs.
    expect(branchPaths.contains(AiChatRoutes.voice), isFalse);
    expect(branchPaths.contains(AiChatRoutes.history), isFalse);
  });
}
