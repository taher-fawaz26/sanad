part of 'ai_chat_bloc.dart';

/// Base type for everything the chat bloc reacts to.
///
/// Named `AiChatBlocEvent` rather than the usual `AiChatEvent` because the
/// protocol already owns that name for the transport envelope, and both are in
/// scope in this file.
sealed class AiChatBlocEvent extends Equatable {
  /// Const so subclasses can be const.
  const AiChatBlocEvent();

  @override
  List<Object?> get props => [];
}

/// Subscribes to the event source. Safe to add more than once — a second
/// subscription replaces the first.
final class AiChatStarted extends AiChatBlocEvent {
  /// Creates the start event.
  const AiChatStarted();
}

/// A user turn, from the composer or from a `send_message` action.
final class AiChatMessageSubmitted extends AiChatBlocEvent {
  /// Creates a submission carrying [text] and any [attachments].
  const AiChatMessageSubmitted(this.text, {this.attachments = const []});

  /// Raw composer text. Trimmed by the handler; empty input is ignored
  /// **unless** [attachments] carries something.
  final String text;

  /// Images, documents and voice notes to send with this turn.
  ///
  /// Already `ready`: the composer prepares them before submitting. That
  /// matters because this handler runs under `droppable()` — doing the
  /// picking or encoding here would widen the await window and silently
  /// swallow the user's next tap.
  final List<AiChatAttachment> attachments;

  @override
  List<Object?> get props => [text, attachments];
}

/// A structured answer to a semantic node, from Chat or from a capability
/// handler that resolved one.
///
/// A separate event from [AiChatMessageSubmitted] even though both end in a
/// user bubble: this one carries the correlation and the typed value, and the
/// transport call it makes is a different one. Collapsing them would mean
/// every send site had to reason about which half was populated.
final class AiChatInteractionSubmitted extends AiChatBlocEvent {
  /// Creates a submission carrying [interaction].
  const AiChatInteractionSubmitted(this.interaction);

  /// The answer, already built and already accepted by the ledger.
  final AiUiInteraction interaction;

  @override
  List<Object?> get props => [interaction];
}

/// One frame off the transport, re-entered through the bloc so every state
/// change goes through a single ordered queue.
final class AiChatTransportEventReceived extends AiChatBlocEvent {
  /// Creates a wrapper around a decoded transport [event].
  const AiChatTransportEventReceived(this.event);

  /// The decoded protocol envelope.
  final AiChatEvent event;

  @override
  List<Object?> get props => [event];
}
