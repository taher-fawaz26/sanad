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
  /// Creates a submission carrying [text].
  const AiChatMessageSubmitted(this.text);

  /// Raw composer text. Trimmed by the handler; empty input is ignored.
  final String text;

  @override
  List<Object?> get props => [text];
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
