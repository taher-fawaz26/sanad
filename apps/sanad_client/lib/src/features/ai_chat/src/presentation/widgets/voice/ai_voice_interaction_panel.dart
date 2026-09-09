import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:design_system/design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';

/// The card the assistant is waiting on, during a live-voice session.
///
/// ## Why the same surface as chat
///
/// It *is* the same surface. `AiUiSurface` has no chat knowledge — the node
/// says "I need a time slot", and the client decides how that looks here. So a
/// time-slot card in voice and one in the conversation are one renderer, one
/// interaction model and one ledger, differing only in the panel around them
/// and the transport the answer leaves by.
///
/// ## Why an inline panel and not a bottom sheet
///
/// A sheet is a route, and a route on top of the voice route is a second
/// lifecycle to keep in step with the microphone: ending the session, or
/// backgrounding the app, would each have to remember to dismiss it. Drawn
/// inside the screen, the panel disappears exactly when the state that
/// produced it does, and there is nothing extra to tear down.
///
/// ## Rebuild scoping
///
/// A `BlocSelector` on the document alone. The voice screen is fed a
/// microphone level dozens of times a second, and none of those readings
/// reach bloc state at all — but selecting on one field keeps that true even
/// if something else in the state starts changing often.
class AiVoiceInteractionPanel extends StatelessWidget {
  /// Creates the panel.
  const AiVoiceInteractionPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<AiVoiceSessionBloc, AiVoiceSessionState, AiUiDocument?>(
      selector: (state) => state.document,
      builder: (context, document) {
        if (document == null || document.isEmpty) {
          return const SizedBox.shrink();
        }

        return RepaintBoundary(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: ConstrainedBox(
              // The panel must not swallow the control on a small screen: a
              // long card scrolls inside its own box instead of pushing the
              // session's own affordances off the bottom. The hero above it
              // scales down to make room (see `AiVoiceSessionPage`), which is
              // what lets this be generous enough that a card's primary
              // button is usually reachable without scrolling.
              constraints: BoxConstraints(
                maxHeight: MediaQuery.sizeOf(context).height * 0.58,
              ),
              child: SingleChildScrollView(
                child: AiUiSurface(
                  document: document,
                  // Voice has no message ids — there are no assistant messages
                  // to correlate against, only the live session. The node id
                  // alone identifies the question here.
                  gap: AppSpacing.md,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
