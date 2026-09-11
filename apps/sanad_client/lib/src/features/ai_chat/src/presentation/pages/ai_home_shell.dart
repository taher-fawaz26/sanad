import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_home_header.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/widgets/home/ai_home_nav_pill.dart';
import 'package:sanad_client/src/features/ai_chat/src/routes/ai_chat_routes.dart';
import 'package:sanad_client/src/routing/client_routes.dart';
import 'package:sanad_client/src/ui/background/client_ambient_background.dart';

/// Wraps the Sanad / Requests / My Life branches with the persistent header
/// — Figma `Chat – 01 Home`'s top row, present no matter which branch is
/// active.
///
/// Mirrors `sanad_provider`'s `MainShell`: `navigationShell` is go_router's
/// own per-branch state (each branch keeps its own `Navigator`, its own
/// scroll position, its own place in that branch's back stack), so switching
/// segments here never rebuilds — let alone re-fetches or reconnects — a
/// branch that already has state to preserve. That is the whole reason this
/// is a shell and not three routes reached by `context.go`: the AI chat
/// branch alone owns a live transport connection and an audio session, and
/// tearing that down every time someone glances at Requests would be a
/// regression, not a navigation detail.
///
/// The header itself is *not* per-branch — a `StatefulShellRoute` gives one
/// persistent chrome for exactly this reason, so it is built once here
/// rather than duplicated into every branch's own page.
class AiHomeShell extends StatelessWidget {
  /// Creates the shell.
  const AiHomeShell({required this.navigationShell, super.key});

  /// Indexed-stack navigation shell from go_router.
  final StatefulNavigationShell navigationShell;

  static const List<AiHomeDestination> _destinations = [
    AiHomeDestination.sanad,
    AiHomeDestination.requests,
    AiHomeDestination.myLife,
  ];

  void _goBranch(AiHomeDestination destination) {
    final index = _destinations.indexOf(destination);
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    // Transparent, so the ambient wash below is the only background on this
    // surface. Left opaque, the Scaffold painted its own colour across the
    // whole shell and the header sat on a flat band of it — reading exactly
    // like the app bar Figma does not have here.
    backgroundColor: Colors.transparent,
    // The wash belongs to the shell, not to one branch. It used to live
    // inside the chat page, which starts *below* this header — so the header
    // strip fell outside the gradient and showed the Scaffold colour instead,
    // visibly banding the top of the screen. Hoisting it here lets one
    // continuous background run the full height, with the nav floating on top
    // of it as Figma draws it, and gives the sibling branches the same page
    // rather than a bare surface.
    body: ClientAmbientBackground(
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            AiHomeHeader(
              selected: _destinations[navigationShell.currentIndex],
              onSelected: _goBranch,
              onProfileTap: () => context.push(ClientRoutes.profile),
              // Gated with the same constant that gates the route itself, in
              // `AiChatModule.routes` — otherwise a release build renders a
              // button whose destination does not exist (A-10).
              onHistoryTap: kReleaseMode
                  ? null
                  : () => context.push(AiChatRoutes.history),
            ),
            Expanded(child: navigationShell),
          ],
        ),
      ),
    ),
  );
}
