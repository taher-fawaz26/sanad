import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';

/// The standing white → green wash behind the whole AI surface — Figma's
/// `linear-gradient(203.88deg, #F9F9FA 59.3%, #C9FBD8 97.1%)` (`7137:30295`).
///
/// Lives on the shell so it runs the full height of the screen, *behind the
/// navigation too*. Kept in the chat page instead, it started below the
/// header and left a visible band of bare Scaffold colour across the top.
///
/// This is the half of the background both page states share, and it is
/// **static by construction** — no ticker, no state, `const`-constructible.
/// The landing state's drifting glow is a separate layer that lives with the
/// conversation Bloc (`_LandingAmbience` in `ai_chat_page.dart`): only that
/// layer needs to know whether a conversation has started, and the Bloc that
/// answers is scoped to the chat branch, not to this shell. Reading it up
/// here threw `ProviderNotFoundException` on launch.
class AiChatBackground extends StatelessWidget {
  /// Creates the wash around [child].
  const AiChatBackground({required this.child, super.key});

  /// Figma's stop positions along the gradient's own axis.
  static const _clearStop = 0.593;
  static const _greenStop = 0.971;

  /// The gradient runs at 203.88° in CSS terms — down and slightly toward the
  /// leading edge. Expressed as directional alignments so it mirrors under
  /// RTL along with the rest of the page.
  static const AlignmentGeometry _begin = AlignmentDirectional.topEnd;
  static const AlignmentGeometry _end = AlignmentDirectional.bottomStart;

  /// Painted above the wash.
  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: LinearGradient(
        begin: _begin,
        end: _end,
        colors: [
          // `#F9F9FA` — the page's own near-white, which the theme already
          // carries as `background`.
          context.appColors.background,
          // Figma's `#C9FBD8`. Deliberately a literal: it is a mint the
          // palette has no entry for — `MainPalette.shade100` (`#C3FEED`) is
          // visibly more cyan — and this colour is what gives the AI surface
          // its identity, so matching the design beats reaching for the
          // nearest token.
          const Color(0xFFC9FBD8),
        ],
        stops: const [_clearStop, _greenStop],
      ),
    ),
    child: child,
  );
}
