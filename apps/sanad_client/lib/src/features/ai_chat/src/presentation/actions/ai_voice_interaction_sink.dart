import 'package:ai_ui_protocol/ai_ui_protocol.dart';
import 'package:ai_ui_renderer/ai_ui_renderer.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/actions/ai_chat_interaction_sink.dart';
import 'package:sanad_client/src/features/ai_chat/src/presentation/bloc/ai_voice_session_bloc.dart';

/// Carries a card's answer into the live-voice session.
///
/// The voice half of the seam, and deliberately the same shape as
/// `AiChatBlocInteractionSink`: both take the interaction the renderer built,
/// fill in prose for a result the agent wrote no template for, and hand it to
/// their own transport. Everything above them — the result model, the ledger,
/// the renderers, the validation — is one implementation shared by both.
///
/// That symmetry is the design. A `time_slots` card does not know which
/// session it is in, and neither transport knows anything about time slots.
final class AiVoiceInteractionSink implements AiUiInteractionSink {
  /// Creates a sink that answers through [bloc].
  const AiVoiceInteractionSink(this.bloc);

  /// Owns the session and the ledger this sink resolves.
  final AiVoiceSessionBloc bloc;

  @override
  void submit(AiUiInteraction interaction) => bloc.add(
    AiVoiceSessionInteractionSubmitted(withInteractionProse(interaction)),
  );
}
