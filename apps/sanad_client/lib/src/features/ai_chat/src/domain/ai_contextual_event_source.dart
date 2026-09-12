import 'package:sanad_client/src/features/ai_chat/src/domain/entities/chat_context_content.dart';

/// An `AiChatEventSource` that also publishes **contextual** content — things
/// the conversation has to offer that are not a turn in it.
///
/// Opt-in rather than a member on the base interface, exactly like
/// `AiMultimodalEventSource` and `AiInteractiveEventSource`: a transport whose
/// agent has no side channel should not have to implement one, and the
/// consumer decides what to do when the capability is absent. Today only the
/// local source implements it; the live transports gain it when the agent's
/// contract grows a channel for it.
///
/// The stream is the *only* way contextual content reaches the UI. That is the
/// invariant worth keeping: the contextual surface renders an agent-supplied
/// document and never invents business data of its own.
///
/// `null` means "there is nothing on offer" and withdraws whatever was there.
abstract interface class AiContextualEventSource {
  /// Contextual payloads, newest wins. Broadcast, like the event stream
  /// beside it.
  Stream<ChatContextContent?> get contextualContent;
}
