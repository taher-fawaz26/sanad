import 'package:design_system/design_system.dart';
import 'package:flutter/widgets.dart';

/// The client's standing page wash, painted behind a whole screen.
///
/// The gradient itself is [AmbientBackgroundTokens] — Figma's
/// `linear-gradient(203.89deg, #F9F9FA 59.275%, #C9FBD8 97.118%)`. This widget
/// only decides *where* it is painted; the colours, stops and angle are the
/// design system's to own, so a correction lands in one place and reaches
/// every consumer.
///
/// ## Why it lives in `src/ui/` and not in a feature
///
/// It used to be `AiChatBackground`, under `features/ai_chat/`. That is where
/// it was first needed, and it is exactly why the Requests screen never got
/// it: a sibling shell branch reaching into another feature's `presentation/`
/// folder for its own background is a dependency nobody wants to write, so
/// Requests shipped an opaque `Scaffold` instead and painted flat grey over
/// the wash the shell had already drawn. Sitting beside `ui/glass/`, which has
/// the same "shared by every client surface, owned by none of them" shape,
/// makes reuse the easy path.
///
/// **Static by construction** — no ticker, no state, `const`-constructible.
/// The landing state's drifting glow is a separate layer that lives with the
/// conversation Bloc (`_LandingAmbience` in `ai_chat_page.dart`): only that
/// layer needs to know whether a conversation has started.
///
/// Mount it once per screen, as high as possible. Below a header it starts
/// below the header, and the strip above shows bare `Scaffold` colour — the
/// visible band this was hoisted onto the shell to remove.
class ClientAmbientBackground extends StatelessWidget {
  /// Creates the wash around [child].
  const ClientAmbientBackground({required this.child, super.key});

  /// Painted above the wash.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final direction = Directionality.of(context);

    // The gradient's endpoints depend on the box: CSS fixes the *angle* and
    // derives the axis from the box's own size, which two fixed alignments
    // cannot express. One layout pass on a full-screen background is cheap,
    // and it is what makes the stop percentages mean what Figma means.
    return LayoutBuilder(
      builder: (context, constraints) => DecoratedBox(
        decoration: BoxDecoration(
          gradient: AmbientBackgroundTokens.gradient(
            colors: colors,
            size: constraints.biggest,
            direction: direction,
          ),
        ),
        child: child,
      ),
    );
  }
}
